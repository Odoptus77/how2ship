/** Gemeinsame Typen – Statuswerte entsprechen `ShipmentStatus` in der iOS-App (PaketlotseCore). */

export const CARRIERS = ["dhl", "deutschePost", "hermes", "dpd", "gls", "ups"] as const;
export type Carrier = (typeof CARRIERS)[number];

export type ShipmentStatus = "registered" | "inTransit" | "outForDelivery" | "delivered" | "problem";

export interface TrackingEvent {
  /** ISO-8601 */
  date: string;
  text: string;
  location?: string;
  status: ShipmentStatus;
}

/** Ergebnis einer Abfrage beim Tracking-Anbieter (bereits normalisiert). */
export interface TrackingResult {
  status: ShipmentStatus;
  events: TrackingEvent[];
  expectedDelivery?: string;
  /** Referenz beim Anbieter (z. B. Ship24-Tracker-ID). */
  providerRef?: string;
}

export interface ShipmentRecord {
  id: string;
  deviceId: string;
  number: string;
  carrier: Carrier;
  name?: string;
  status: ShipmentStatus;
  provider: string;
  providerRef?: string;
  expectedDelivery?: string;
  deliveredAt?: string;
  lastCheckedAt?: string;
  nextCheckAt?: string;
  createdAt: string;
  updatedAt: string;
}

/** Antwortformat der API (vom iOS-Client gelesen). */
export interface ShipmentDTO {
  id: string;
  number: string;
  carrier: Carrier;
  name?: string;
  status: ShipmentStatus;
  expectedDelivery?: string;
  deliveredAt?: string;
  updatedAt: string;
  events: TrackingEvent[];
}

export function isCarrier(value: unknown): value is Carrier {
  return typeof value === "string" && (CARRIERS as readonly string[]).includes(value);
}

/** Wie die App: Großbuchstaben, nur A–Z/0–9. */
export function normalizeTrackingNumber(raw: string): string {
  return raw.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

export function isFinal(status: ShipmentStatus): boolean {
  return status === "delivered";
}
