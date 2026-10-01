import { randomUUID } from "node:crypto";
import type { Config } from "./config.js";
import type { Database } from "./db.js";
import {
  type Carrier,
  isFinal,
  normalizeTrackingNumber,
  type ShipmentDTO,
  type ShipmentRecord,
  type ShipmentStatus,
  type TrackingResult,
} from "./model.js";
import type { ProviderRegistry } from "./providers/index.js";
import { ProviderError } from "./providers/types.js";
import type { PushSender } from "./push/apns.js";
import { notifiableChange, pushText } from "./status.js";

export class ServiceError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
  ) {
    super(message);
  }
}

const HOUR = 3_600_000;

/** Wann erneut abfragen? Anbieter mit Webhook nur selten als Sicherheitsnetz. */
export function nextCheckDelay(status: ShipmentStatus, pushesUpdates: boolean): number | undefined {
  if (isFinal(status)) return undefined;
  if (pushesUpdates) return 12 * HOUR;
  switch (status) {
    case "outForDelivery":
      return 1 * HOUR;
    case "problem":
      return 6 * HOUR;
    default:
      return 3 * HOUR;
  }
}

export class TrackingService {
  constructor(
    private readonly db: Database,
    private readonly providers: ProviderRegistry,
    private readonly push: PushSender,
    private readonly config: Config,
    private readonly now: () => Date = () => new Date(),
    private readonly log: (line: string) => void = () => {},
  ) {}

  async register(deviceId: string, rawNumber: string, carrier: Carrier, name?: string): Promise<ShipmentDTO> {
    const number = normalizeTrackingNumber(rawNumber);
    if (number.length < 8 || number.length > 40) throw new ServiceError("Ungültige Sendungsnummer", 400);

    const existing = this.db.findShipment(deviceId, number);
    if (existing) return this.dto(existing);

    if (this.db.countActiveShipments(deviceId) >= this.config.maxActiveShipmentsPerDevice) {
      throw new ServiceError(`Maximal ${this.config.maxActiveShipmentsPerDevice} aktive Sendungen gleichzeitig`, 429);
    }
    const provider = this.providers.forCarrier(carrier);
    if (!provider) throw new ServiceError("Für diesen Paketdienst ist keine Sendungsverfolgung eingerichtet", 503);

    const now = this.now().toISOString();
    const record: ShipmentRecord = {
      id: randomUUID(),
      deviceId,
      number,
      carrier,
      name: name?.trim() || undefined,
      status: "registered",
      provider: provider.name,
      createdAt: now,
      updatedAt: now,
      // Falls die erste Abfrage scheitert: bald erneut versuchen.
      nextCheckAt: new Date(this.now().getTime() + 15 * 60_000).toISOString(),
    };
    this.db.insertShipment(record);

    try {
      const result = await provider.register(number, carrier);
      await this.apply(record, result, { notify: false });
    } catch (error) {
      // Nicht fatal: Viele Nummern sind erst nach Einlieferung beim Anbieter bekannt.
      this.log(`[tracking] Erstabfrage ${number} fehlgeschlagen: ${(error as Error).message}`);
    }
    return this.dto(this.db.getShipment(record.id)!);
  }

  list(deviceId: string): ShipmentDTO[] {
    return this.db.listShipments(deviceId).map((s) => this.dto(s));
  }

  get(deviceId: string, id: string): ShipmentDTO {
    const shipment = this.db.getShipment(id);
    if (!shipment || shipment.deviceId !== deviceId) throw new ServiceError("Sendung nicht gefunden", 404);
    return this.dto(shipment);
  }

  remove(deviceId: string, id: string) {
    const shipment = this.db.getShipment(id);
    if (!shipment || shipment.deviceId !== deviceId) throw new ServiceError("Sendung nicht gefunden", 404);
    this.db.deleteShipment(id);
  }

  /** Manuelle Aktualisierung (Pull-to-Refresh) – höchstens alle 5 Minuten beim Anbieter nachfragen. */
  async refresh(deviceId: string, id: string): Promise<ShipmentDTO> {
    const shipment = this.db.getShipment(id);
    if (!shipment || shipment.deviceId !== deviceId) throw new ServiceError("Sendung nicht gefunden", 404);
    const last = shipment.lastCheckedAt ? Date.parse(shipment.lastCheckedAt) : 0;
    if (!isFinal(shipment.status) && this.now().getTime() - last > 5 * 60_000) {
      await this.check(shipment);
    }
    return this.dto(this.db.getShipment(id)!);
  }

  /** Eine Sendung beim Anbieter abfragen (Poller und Refresh). */
  async check(shipment: ShipmentRecord): Promise<void> {
    const provider = this.providers.byProviderName(shipment.provider);
    if (!provider) return;
    try {
      const result = await provider.fetch(shipment.number, shipment.carrier, shipment.providerRef);
      await this.apply(shipment, result, { notify: true });
    } catch (error) {
      const retryable = !(error instanceof ProviderError) || error.retryable;
      const delay = retryable ? 1 * HOUR : 24 * HOUR;
      this.db.updateShipment({
        ...shipment,
        lastCheckedAt: this.now().toISOString(),
        nextCheckAt: new Date(this.now().getTime() + delay).toISOString(),
      });
      this.log(`[tracking] Abfrage ${shipment.number} fehlgeschlagen: ${(error as Error).message}`);
    }
  }

  /** Webhook eines Anbieters: Ergebnis allen Sendungen mit dieser Anbieter-Referenz zuordnen. */
  async applyWebhook(provider: string, providerRef: string, result: TrackingResult): Promise<number> {
    const shipments = this.db.findByProviderRef(provider, providerRef);
    for (const shipment of shipments) await this.apply(shipment, result, { notify: true });
    return shipments.length;
  }

  /** Ergebnis übernehmen, neue Ereignisse speichern, bei relevantem Statuswechsel Push senden. */
  async apply(shipment: ShipmentRecord, result: TrackingResult, options: { notify: boolean }) {
    const now = this.now();
    this.db.addEvents(shipment.id, result.events);
    const provider = this.providers.byProviderName(shipment.provider);
    const delay = nextCheckDelay(result.status, provider?.pushesUpdates ?? false);

    const updated: ShipmentRecord = {
      ...shipment,
      status: result.status,
      providerRef: result.providerRef ?? shipment.providerRef,
      expectedDelivery: result.expectedDelivery ?? shipment.expectedDelivery,
      deliveredAt:
        result.status === "delivered"
          ? shipment.deliveredAt ??
            result.events.find((e) => e.status === "delivered")?.date ??
            now.toISOString()
          : shipment.deliveredAt,
      lastCheckedAt: now.toISOString(),
      nextCheckAt: delay === undefined ? undefined : new Date(now.getTime() + delay).toISOString(),
      updatedAt: result.status !== shipment.status ? now.toISOString() : shipment.updatedAt,
    };
    this.db.updateShipment(updated);

    const change = notifiableChange(shipment.status, result.status);
    if (options.notify && change) await this.notify(updated, change);
  }

  private async notify(shipment: ShipmentRecord, status: ShipmentStatus) {
    const device = this.db.getDevice(shipment.deviceId);
    if (!device?.pushToken) return;
    const label = shipment.name ?? `Dein Paket (…${shipment.number.slice(-6)})`;
    const result = await this.push.send(device.pushToken, { ...pushText(status, label), data: { shipmentId: shipment.id } }, device.pushSandbox);
    if (result === "invalid-token") this.db.updatePushToken(device.id, null, false);
  }

  /** Datensparsamkeit: zugestellte Sendungen nach X Tagen löschen. */
  purgeExpired(): number {
    const before = new Date(this.now().getTime() - this.config.retentionDaysAfterDelivery * 24 * HOUR).toISOString();
    return this.db.purgeDelivered(before);
  }

  dto(shipment: ShipmentRecord): ShipmentDTO {
    return {
      id: shipment.id,
      number: shipment.number,
      carrier: shipment.carrier,
      name: shipment.name,
      status: shipment.status,
      expectedDelivery: shipment.expectedDelivery,
      deliveredAt: shipment.deliveredAt,
      updatedAt: shipment.updatedAt,
      events: this.db.events(shipment.id),
    };
  }
}
