import { test } from "node:test";
import assert from "node:assert/strict";
import { notifiableChange, statusFromDHL, statusFromShip24 } from "../src/status.js";
import { parseDHLResponse } from "../src/providers/dhl.js";
import { parseShip24Tracking } from "../src/providers/ship24.js";

test("DHL-Statuscodes werden normalisiert", () => {
  assert.equal(statusFromDHL("pre-transit"), "registered");
  assert.equal(statusFromDHL("transit", "Die Sendung wurde im Paketzentrum bearbeitet."), "inTransit");
  assert.equal(statusFromDHL("transit", "Die Sendung wurde in das Zustellfahrzeug geladen."), "outForDelivery");
  assert.equal(statusFromDHL("delivered"), "delivered");
  assert.equal(statusFromDHL("failure"), "problem");
  assert.equal(statusFromDHL("unknown"), "registered");
});

test("Ship24-Meilensteine werden normalisiert", () => {
  assert.equal(statusFromShip24("info_received"), "registered");
  assert.equal(statusFromShip24("in_transit"), "inTransit");
  assert.equal(statusFromShip24("available_for_pickup"), "inTransit");
  assert.equal(statusFromShip24("out_for_delivery"), "outForDelivery");
  assert.equal(statusFromShip24("failed_attempt"), "problem");
  assert.equal(statusFromShip24("delivered"), "delivered");
  assert.equal(statusFromShip24(null), "registered");
});

test("Push nur bei relevanten Statuswechseln", () => {
  assert.equal(notifiableChange("registered", "inTransit"), "inTransit");
  assert.equal(notifiableChange("inTransit", "inTransit"), undefined);
  assert.equal(notifiableChange("inTransit", "outForDelivery"), "outForDelivery");
  assert.equal(notifiableChange("outForDelivery", "delivered"), "delivered");
  assert.equal(notifiableChange("inTransit", "problem"), "problem");
  // Rückkehr von „Problem“ zu „unterwegs“ ist keine Nachricht wert
  assert.equal(notifiableChange("problem", "inTransit"), undefined);
  // Nach Zustellung keine Nachrichten mehr
  assert.equal(notifiableChange("delivered", "problem"), undefined);
});

test("DHL-Antwort wird gelesen", () => {
  const result = parseDHLResponse({
    shipments: [
      {
        id: "00340434161094042557",
        status: {
          timestamp: "2026-10-01T09:12:00+02:00",
          statusCode: "transit",
          status: "In Zustellung",
          description: "Die Sendung wurde in das Zustellfahrzeug geladen.",
        },
        estimatedTimeOfDelivery: "2026-10-01T18:00:00+02:00",
        events: [
          {
            timestamp: "2026-10-01T09:12:00+02:00",
            statusCode: "transit",
            description: "Die Sendung wurde in das Zustellfahrzeug geladen.",
            location: { address: { addressLocality: "Berlin" } },
          },
          { timestamp: "2026-09-30T20:00:00+02:00", statusCode: "transit", description: "Die Sendung wurde im Start-Paketzentrum bearbeitet." },
          { timestamp: "2026-09-30T08:00:00+02:00", statusCode: "pre-transit", description: "Die Auftragsdaten zu dieser Sendung wurden übermittelt." },
        ],
      },
    ],
  });
  assert.equal(result.status, "outForDelivery");
  assert.equal(result.events.length, 3);
  assert.equal(result.events[0].location, "Berlin");
  assert.equal(result.events[0].date, "2026-10-01T07:12:00.000Z");
  assert.equal(result.events[2].status, "registered");
  assert.equal(result.expectedDelivery, "2026-10-01T16:00:00.000Z");
});

test("DHL-Antwort ohne Sendung ist ein (wiederholbarer) Fehler", () => {
  assert.throws(() => parseDHLResponse({ shipments: [] }), /keine Sendung/);
});

test("Ship24-Tracking wird gelesen", () => {
  const result = parseShip24Tracking({
    tracker: { trackerId: "tr-123", trackingNumber: "01234567890123" },
    shipment: { statusMilestone: "out_for_delivery", delivery: { estimatedDeliveryDate: "2026-10-02T00:00:00" } },
    events: [
      { status: "Zustellung heute", occurrenceDatetime: "2026-10-01T08:00:00", location: "Köln", statusMilestone: "out_for_delivery" },
      { status: "Im Depot eingetroffen", occurrenceDatetime: "2026-09-30T22:00:00+02:00", statusMilestone: "in_transit" },
    ],
  });
  assert.equal(result.status, "outForDelivery");
  assert.equal(result.providerRef, "tr-123");
  assert.equal(result.events[0].date, "2026-10-01T08:00:00.000Z");
  assert.equal(result.events[1].date, "2026-09-30T20:00:00.000Z");
  assert.equal(result.expectedDelivery, "2026-10-02T00:00:00.000Z");
});
