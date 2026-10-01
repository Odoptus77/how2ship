import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes, randomUUID } from "node:crypto";
import { loadConfig } from "../src/config.js";
import { Database } from "../src/db.js";
import { Poller } from "../src/poller.js";
import { ProviderRegistry } from "../src/providers/index.js";
import { MockProvider } from "../src/providers/mock.js";
import type { TrackingProvider } from "../src/providers/types.js";
import { LogPushSender } from "../src/push/apns.js";
import { buildServer } from "../src/server.js";
import { nextCheckDelay, TrackingService } from "../src/tracking-service.js";

/** Testumgebung mit steuerbarer Uhr, Mock-Anbieter und Push-Protokoll. */
function setup(options: { ship24?: TrackingProvider } = {}) {
  let now = Date.parse("2026-10-01T08:00:00Z");
  const clock = { advance: (minutes: number) => (now += minutes * 60_000), now: () => new Date(now) };
  const config = { ...loadConfig({}), ship24WebhookSecret: "webhook-secret-123", maxActiveShipmentsPerDevice: 3 };
  const db = new Database(":memory:");
  const providers = options.ship24
    ? new ProviderRegistry(undefined, options.ship24, undefined)
    : new ProviderRegistry(undefined, undefined, new MockProvider(2, () => now));
  const push = new LogPushSender();
  const service = new TrackingService(db, providers, push, config, clock.now);
  const poller = new Poller(db, service, 60);
  const app = buildServer({ config, db, service, providerNames: providers.names });
  const device = { id: randomUUID(), secret: randomBytes(32).toString("hex") };
  const headers = { "x-device-id": device.id, authorization: `Bearer ${device.secret}` };
  return { app, db, service, poller, push, clock, headers, device };
}

test("Gerät wird beim ersten Aufruf angelegt, falsches Geheimnis abgelehnt", async () => {
  const { app, headers, device } = setup();
  const first = await app.inject({ method: "GET", url: "/v1/shipments", headers });
  assert.equal(first.statusCode, 200);
  assert.deepEqual(first.json(), { shipments: [] });

  const wrong = await app.inject({
    method: "GET",
    url: "/v1/shipments",
    headers: { "x-device-id": device.id, authorization: `Bearer ${"x".repeat(64)}` },
  });
  assert.equal(wrong.statusCode, 401);

  const missing = await app.inject({ method: "GET", url: "/v1/shipments" });
  assert.equal(missing.statusCode, 400);
});

test("Sendung anlegen, Duplikate vermeiden, löschen", async () => {
  const { app, headers } = setup();
  const created = await app.inject({
    method: "POST",
    url: "/v1/shipments",
    headers,
    payload: { number: " 1z999aa1-0123456784 ", carrier: "ups", name: "Geschenk für Oma" },
  });
  assert.equal(created.statusCode, 201);
  const shipment = created.json();
  assert.equal(shipment.number, "1Z999AA10123456784");
  assert.equal(shipment.status, "registered");
  assert.equal(shipment.name, "Geschenk für Oma");
  assert.equal(shipment.events.length, 1);

  const again = await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "1Z999AA10123456784", carrier: "ups" } });
  assert.equal(again.json().id, shipment.id);

  const del = await app.inject({ method: "DELETE", url: `/v1/shipments/${shipment.id}`, headers });
  assert.equal(del.statusCode, 204);
  const list = await app.inject({ method: "GET", url: "/v1/shipments", headers });
  assert.equal(list.json().shipments.length, 0);
});

test("Ungültige Eingaben werden abgelehnt", async () => {
  const { app, headers } = setup();
  const badCarrier = await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "123456789012", carrier: "fedex" } });
  assert.equal(badCarrier.statusCode, 400);
  const tooShort = await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "12-34", carrier: "dhl" } });
  assert.equal(tooShort.statusCode, 400);
  const badToken = await app.inject({ method: "PUT", url: "/v1/device/push-token", headers, payload: { token: "not-hex!" } });
  assert.equal(badToken.statusCode, 400);
});

test("Fremde Sendungen sind nicht sichtbar", async () => {
  const a = setup();
  const created = await a.app.inject({ method: "POST", url: "/v1/shipments", headers: a.headers, payload: { number: "123456789012", carrier: "dhl" } });
  const otherHeaders = { "x-device-id": randomUUID(), authorization: `Bearer ${randomBytes(32).toString("hex")}` };
  const foreign = await a.app.inject({ method: "GET", url: `/v1/shipments/${created.json().id}`, headers: otherHeaders });
  assert.equal(foreign.statusCode, 404);
});

test("Limit aktiver Sendungen pro Gerät", async () => {
  const { app, headers } = setup();
  for (const n of ["111111111111", "222222222222", "333333333333"]) {
    assert.equal((await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: n, carrier: "dhl" } })).statusCode, 201);
  }
  const fourth = await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "444444444444", carrier: "dhl" } });
  assert.equal(fourth.statusCode, 429);
});

test("Poller bringt Statuswechsel und schickt Push-Nachrichten", async () => {
  const { app, headers, poller, push, clock } = setup();
  await app.inject({ method: "PUT", url: "/v1/device/push-token", headers, payload: { token: "ab".repeat(32), sandbox: true } });
  const created = (await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "00340434161094042557", carrier: "dhl", name: "Schuhe" } })).json();

  // Mock: alle 2 Minuten ein Schritt. Poller fragt fällige Sendungen ab (nächste Abfrage nach 3 h).
  clock.advance(3 * 60);
  assert.equal(await poller.tick(clock.now()), 1);
  let shipment = (await app.inject({ method: "GET", url: `/v1/shipments/${created.id}`, headers })).json();
  assert.equal(shipment.status, "delivered");
  assert.ok(shipment.deliveredAt);
  assert.equal(shipment.events.length, 4);
  assert.deepEqual(push.sent.map((p) => p.message.title), ["Zugestellt ✅"]);
  assert.match(push.sent[0].message.body, /Schuhe/);
  assert.equal(push.sent[0].message.data?.shipmentId, created.id);

  // Zugestellt → keine weiteren Abfragen
  clock.advance(24 * 60);
  assert.equal(await poller.tick(clock.now()), 0);
});

test("Refresh fragt sofort nach, höchstens alle 5 Minuten", async () => {
  const { app, headers, clock } = setup();
  const created = (await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "00340434161094042557", carrier: "dhl" } })).json();
  clock.advance(3);
  const tooSoon = (await app.inject({ method: "POST", url: `/v1/shipments/${created.id}/refresh`, headers })).json();
  assert.equal(tooSoon.status, "registered");
  clock.advance(3);
  // 6 Minuten nach Anlage → Mock-Sendung (1 Schritt je 2 min) ist zugestellt
  const refreshed = (await app.inject({ method: "POST", url: `/v1/shipments/${created.id}/refresh`, headers })).json();
  assert.equal(refreshed.status, "delivered");
});

test("Zugestellte Sendungen werden nach 30 Tagen gelöscht", async () => {
  const { app, headers, poller, clock } = setup();
  await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "00340434161094042557", carrier: "dhl" } });
  clock.advance(3 * 60);
  await poller.tick(clock.now());
  clock.advance(31 * 24 * 60);
  await poller.tick(clock.now());
  const list = (await app.inject({ method: "GET", url: "/v1/shipments", headers })).json();
  assert.equal(list.shipments.length, 0);
});

test("Ship24-Webhook aktualisiert die passende Sendung", async () => {
  const ship24: TrackingProvider = {
    name: "ship24",
    pushesUpdates: true,
    async register() {
      return { status: "registered", events: [], providerRef: "tr-42" };
    },
    async fetch() {
      return { status: "registered", events: [], providerRef: "tr-42" };
    },
  };
  const { app, headers, push } = setup({ ship24 });
  await app.inject({ method: "PUT", url: "/v1/device/push-token", headers, payload: { token: "cd".repeat(32) } });
  const created = (await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "01234567890123", carrier: "hermes" } })).json();

  const payload = {
    trackings: [
      {
        tracker: { trackerId: "tr-42" },
        shipment: { statusMilestone: "out_for_delivery" },
        events: [{ status: "Zustellung heute", occurrenceDatetime: "2026-10-01T08:00:00Z", statusMilestone: "out_for_delivery" }],
      },
    ],
  };
  const unauthorized = await app.inject({ method: "POST", url: "/v1/webhooks/ship24", payload, headers: { authorization: "Bearer falsch" } });
  assert.equal(unauthorized.statusCode, 401);

  const ok = await app.inject({ method: "POST", url: "/v1/webhooks/ship24", payload, headers: { authorization: "Bearer webhook-secret-123" } });
  assert.deepEqual(ok.json(), { received: 1, matched: 1 });
  const shipment = (await app.inject({ method: "GET", url: `/v1/shipments/${created.id}`, headers })).json();
  assert.equal(shipment.status, "outForDelivery");
  assert.deepEqual(push.sent.map((p) => p.message.title), ["Heute in Zustellung 📦"]);
});

test("Gerät löschen entfernt alle Daten (DSGVO)", async () => {
  const { app, headers, db, device } = setup();
  await app.inject({ method: "POST", url: "/v1/shipments", headers, payload: { number: "123456789012", carrier: "dhl" } });
  assert.equal((await app.inject({ method: "DELETE", url: "/v1/device", headers })).statusCode, 204);
  assert.equal(db.getDevice(device.id), undefined);
  assert.equal(db.listShipments(device.id).length, 0);
});

test("Abfrage-Intervalle", () => {
  assert.equal(nextCheckDelay("delivered", false), undefined);
  assert.equal(nextCheckDelay("outForDelivery", false), 3_600_000);
  assert.equal(nextCheckDelay("inTransit", false), 3 * 3_600_000);
  assert.equal(nextCheckDelay("inTransit", true), 12 * 3_600_000);
});
