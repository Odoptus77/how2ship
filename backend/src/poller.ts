import type { Database } from "./db.js";
import type { TrackingService } from "./tracking-service.js";

/**
 * Fragt fällige Sendungen regelmäßig ab und räumt alte Daten auf.
 * Läuft im selben Prozess wie die API – für den Start ausreichend (ein Server).
 */
export class Poller {
  private timer?: NodeJS.Timeout;
  private running = false;

  constructor(
    private readonly db: Database,
    private readonly service: TrackingService,
    private readonly intervalSeconds: number,
    private readonly log: (line: string) => void = () => {},
  ) {}

  start() {
    this.timer = setInterval(() => void this.tick(), this.intervalSeconds * 1000);
    void this.tick();
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
  }

  /** Ein Durchlauf; überspringt, falls der vorherige noch läuft. */
  async tick(now = new Date()): Promise<number> {
    if (this.running) return 0;
    this.running = true;
    try {
      const due = this.db.dueShipments(now.toISOString(), 100);
      for (const shipment of due) {
        await this.service.check(shipment);
      }
      const purged = this.service.purgeExpired();
      if (due.length || purged) this.log(`[poller] ${due.length} abgefragt, ${purged} gelöscht`);
      return due.length;
    } finally {
      this.running = false;
    }
  }
}
