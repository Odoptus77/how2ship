import type { Carrier, TrackingEvent, TrackingResult } from "../model.js";
import { statusFromShip24 } from "../status.js";
import { fetchJSON, ProviderError, type TrackingProvider } from "./types.js";

/**
 * Ship24 – ein Anbieter für Hermes, DPD, GLS, UPS (und DHL, falls kein DHL-Key).
 * Sendet Statuswechsel per Webhook (POST /v1/webhooks/ship24), daher nur seltene Abfragen als Fallback.
 * Doku: https://docs.ship24.com
 *
 * TODO: Kurier-Codes (courierCode) für Hermes/DPD/GLS mit der Ship24-Kurierliste abgleichen –
 * ohne Angabe erkennt Ship24 den Paketdienst automatisch.
 */
export class Ship24Provider implements TrackingProvider {
  readonly name = "ship24";
  readonly pushesUpdates = true;

  constructor(
    private readonly apiKey: string,
    private readonly baseURL = "https://api.ship24.com/public/v1",
  ) {}

  private headers() {
    return { Authorization: `Bearer ${this.apiKey}`, "Content-Type": "application/json", Accept: "application/json" };
  }

  /** Tracker anlegen und direkt Ergebnisse holen (ein Aufruf). */
  async register(number: string, _carrier: Carrier): Promise<TrackingResult> {
    const body = await fetchJSON(`${this.baseURL}/trackers/track`, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ trackingNumber: number, destinationCountryCode: "DE" }),
    });
    return parseShip24Tracking(body?.data?.trackings?.[0]);
  }

  async fetch(number: string, carrier: Carrier, providerRef?: string): Promise<TrackingResult> {
    if (!providerRef) return this.register(number, carrier);
    const body = await fetchJSON(`${this.baseURL}/trackers/${encodeURIComponent(providerRef)}/results`, {
      headers: this.headers(),
    });
    return parseShip24Tracking(body?.data?.trackings?.[0]);
  }
}

/** Eine „tracking“ aus Ship24-Antwort oder -Webhook normalisieren. Reine Funktion – getestet. */
export function parseShip24Tracking(tracking: any): TrackingResult {
  if (!tracking) throw new ProviderError("Ship24: keine Tracking-Daten", true);
  const events: TrackingEvent[] = (tracking.events ?? [])
    .filter((e: any) => e?.occurrenceDatetime)
    .map((e: any) => ({
      date: toISO(e.occurrenceDatetime),
      text: e.status || "Statusänderung",
      location: e.location || undefined,
      status: statusFromShip24(e.statusMilestone),
    }));

  const shipment = tracking.shipment ?? {};
  return {
    status: statusFromShip24(shipment.statusMilestone),
    events,
    expectedDelivery: shipment.delivery?.estimatedDeliveryDate ? toISO(shipment.delivery.estimatedDeliveryDate) : undefined,
    providerRef: tracking.tracker?.trackerId,
  };
}

/** Ship24 liefert lokale Zeitangaben teils ohne Zeitzone – dann als UTC behandeln. */
function toISO(value: string): string {
  const hasZone = /[zZ]|[+-]\d{2}:?\d{2}$/.test(value);
  const date = new Date(hasZone ? value : `${value}Z`);
  return Number.isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
}
