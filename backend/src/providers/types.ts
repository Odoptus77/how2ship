import type { Carrier, TrackingResult } from "../model.js";

export interface TrackingProvider {
  /** Kennung, wird in der Datenbank gespeichert. */
  readonly name: string;
  /** Liefert der Anbieter Updates per Webhook? Dann wird seltener abgefragt. */
  readonly pushesUpdates: boolean;
  /** Sendung beim Anbieter anmelden (falls nötig) und aktuellen Stand holen. */
  register(number: string, carrier: Carrier): Promise<TrackingResult>;
  /** Aktuellen Stand abfragen. */
  fetch(number: string, carrier: Carrier, providerRef?: string): Promise<TrackingResult>;
}

export class ProviderError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean,
  ) {
    super(message);
  }
}

/** Kleiner fetch-Wrapper mit Timeout und verständlichen Fehlern. */
export async function fetchJSON(url: string, init: RequestInit & { timeoutMs?: number } = {}): Promise<any> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), init.timeoutMs ?? 15_000);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    const text = await response.text();
    if (!response.ok) {
      // 404 = (noch) keine Daten beim Anbieter → später erneut versuchen
      const retryable = response.status === 404 || response.status === 429 || response.status >= 500;
      throw new ProviderError(`HTTP ${response.status}: ${text.slice(0, 200)}`, retryable);
    }
    return text ? JSON.parse(text) : {};
  } catch (error) {
    if (error instanceof ProviderError) throw error;
    throw new ProviderError(`Netzwerkfehler: ${(error as Error).message}`, true);
  } finally {
    clearTimeout(timer);
  }
}
