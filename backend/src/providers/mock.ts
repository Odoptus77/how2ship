import type { Carrier, ShipmentStatus, TrackingEvent, TrackingResult } from "../model.js";
import type { TrackingProvider } from "./types.js";

/**
 * Simulierter Anbieter für Entwicklung und Tests: Jede Sendung durchläuft
 * angemeldet → unterwegs → in Zustellung → zugestellt, jeweils nach `stepMinutes`.
 * Nummern, die auf „X“ enden, landen dauerhaft in „Problem“.
 */
export class MockProvider implements TrackingProvider {
  readonly name = "mock";
  readonly pushesUpdates = false;
  private readonly firstSeen = new Map<string, number>();

  constructor(
    private readonly stepMinutes = 2,
    private readonly now: () => number = Date.now,
  ) {}

  async register(number: string, carrier: Carrier): Promise<TrackingResult> {
    if (!this.firstSeen.has(number)) this.firstSeen.set(number, this.now());
    return this.fetch(number, carrier);
  }

  async fetch(number: string, carrier: Carrier): Promise<TrackingResult> {
    const start = this.firstSeen.get(number) ?? this.now();
    if (!this.firstSeen.has(number)) this.firstSeen.set(number, start);
    const stepMs = this.stepMinutes * 60_000;
    const step = Math.min(3, Math.floor((this.now() - start) / stepMs));

    const steps: { status: ShipmentStatus; text: string; location: string }[] = [
      { status: "registered", text: "Die Sendung wurde elektronisch angekündigt.", location: "Online" },
      { status: "inTransit", text: "Die Sendung wurde im Start-Paketzentrum bearbeitet.", location: "Hamburg" },
      { status: "outForDelivery", text: "Die Sendung wurde in das Zustellfahrzeug geladen.", location: "Berlin" },
      { status: "delivered", text: "Die Sendung wurde erfolgreich zugestellt.", location: "Berlin" },
    ];

    if (number.endsWith("X")) {
      return {
        status: "problem",
        events: [
          { date: new Date(start).toISOString(), text: steps[0].text, location: steps[0].location, status: "registered" },
          { date: new Date(start + stepMs).toISOString(), text: "Zustellung nicht möglich – Adresse unklar.", status: "problem" },
        ],
      };
    }

    const events: TrackingEvent[] = steps.slice(0, step + 1).map((s, index) => ({
      date: new Date(start + index * stepMs).toISOString(),
      text: s.text,
      location: s.location,
      status: s.status,
    }));
    return {
      status: steps[step].status,
      events,
      expectedDelivery: new Date(start + 3 * stepMs).toISOString(),
      providerRef: `mock-${carrier}-${number}`,
    };
  }
}
