import type { Carrier, TrackingEvent, TrackingResult } from "../model.js";
import { statusFromDHL } from "../status.js";
import { fetchJSON, ProviderError, type TrackingProvider } from "./types.js";

/**
 * DHL Shipment Tracking – Unified (kostenlos, API-Key über developer.dhl.com).
 * Kein Webhook in der Basisversion → wird regelmäßig abgefragt (Kontingent beachten!).
 * Doku: https://developer.dhl.com/api-reference/shipment-tracking
 */
export class DHLProvider implements TrackingProvider {
  readonly name = "dhl";
  readonly pushesUpdates = false;

  constructor(
    private readonly apiKey: string,
    private readonly baseURL = "https://api-eu.dhl.com/track/shipments",
  ) {}

  register(number: string, carrier: Carrier): Promise<TrackingResult> {
    return this.fetch(number, carrier);
  }

  async fetch(number: string, _carrier?: Carrier): Promise<TrackingResult> {
    const url = `${this.baseURL}?trackingNumber=${encodeURIComponent(number)}&language=de`;
    const body = await fetchJSON(url, { headers: { "DHL-API-Key": this.apiKey, Accept: "application/json" } });
    return parseDHLResponse(body);
  }
}

/** Reine Funktion – getestet mit Beispielantworten. */
export function parseDHLResponse(body: any): TrackingResult {
  const shipment = body?.shipments?.[0];
  if (!shipment) throw new ProviderError("DHL: keine Sendung in der Antwort", true);

  const events: TrackingEvent[] = (shipment.events ?? [])
    .filter((e: any) => e?.timestamp)
    .map((e: any) => {
      const text = e.description || e.status || "Statusänderung";
      return {
        date: new Date(e.timestamp).toISOString(),
        text,
        location: e.location?.address?.addressLocality || undefined,
        status: statusFromDHL(e.statusCode, text),
      };
    });

  const current = shipment.status ?? {};
  const currentText = current.description || current.status || "";
  return {
    status: statusFromDHL(current.statusCode, currentText),
    events,
    expectedDelivery: shipment.estimatedTimeOfDelivery ? new Date(shipment.estimatedTimeOfDelivery).toISOString() : undefined,
  };
}
