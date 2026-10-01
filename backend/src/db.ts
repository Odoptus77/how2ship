import { DatabaseSync } from "node:sqlite";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import type { Carrier, ShipmentRecord, ShipmentStatus, TrackingEvent } from "./model.js";

/**
 * SQLite-Speicher (Node 22 `node:sqlite`, keine nativen Abhängigkeiten).
 * Für den Start mit einem Server völlig ausreichend; bei Bedarf später gegen Postgres tauschbar,
 * da alle Zugriffe über diese Klasse laufen.
 */
export class Database {
  private db: DatabaseSync;

  constructor(path: string) {
    if (path !== ":memory:") mkdirSync(dirname(path), { recursive: true });
    this.db = new DatabaseSync(path);
    this.db.exec("PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;");
    this.migrate();
  }

  private migrate() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY,
        secret_hash TEXT NOT NULL,
        push_token TEXT,
        platform TEXT NOT NULL DEFAULT 'ios',
        push_sandbox INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS shipments (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
        number TEXT NOT NULL,
        carrier TEXT NOT NULL,
        name TEXT,
        status TEXT NOT NULL,
        provider TEXT NOT NULL,
        provider_ref TEXT,
        expected_delivery TEXT,
        delivered_at TEXT,
        last_checked_at TEXT,
        next_check_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (device_id, number)
      );
      CREATE INDEX IF NOT EXISTS idx_shipments_next_check ON shipments(next_check_at);
      CREATE INDEX IF NOT EXISTS idx_shipments_provider_ref ON shipments(provider, provider_ref);
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shipment_id TEXT NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
        occurred_at TEXT NOT NULL,
        text TEXT NOT NULL,
        location TEXT,
        status TEXT NOT NULL,
        UNIQUE (shipment_id, occurred_at, text)
      );
    `);
  }

  close() {
    this.db.close();
  }

  // MARK: Geräte

  getDevice(id: string): { id: string; secretHash: string; pushToken?: string; pushSandbox: boolean } | undefined {
    const row = this.db.prepare("SELECT * FROM devices WHERE id = ?").get(id) as Record<string, any> | undefined;
    return row
      ? { id: row.id, secretHash: row.secret_hash, pushToken: row.push_token ?? undefined, pushSandbox: row.push_sandbox === 1 }
      : undefined;
  }

  insertDevice(id: string, secretHash: string, now: string) {
    this.db
      .prepare("INSERT INTO devices (id, secret_hash, created_at, last_seen_at) VALUES (?, ?, ?, ?)")
      .run(id, secretHash, now, now);
  }

  updatePushToken(id: string, token: string | null, sandbox: boolean) {
    this.db.prepare("UPDATE devices SET push_token = ?, push_sandbox = ? WHERE id = ?").run(token, sandbox ? 1 : 0, id);
  }

  touchDevice(id: string, now: string) {
    this.db.prepare("UPDATE devices SET last_seen_at = ? WHERE id = ?").run(now, id);
  }

  deleteDevice(id: string) {
    this.db.prepare("DELETE FROM devices WHERE id = ?").run(id);
  }

  // MARK: Sendungen

  insertShipment(s: ShipmentRecord) {
    this.db
      .prepare(
        `INSERT INTO shipments (id, device_id, number, carrier, name, status, provider, provider_ref, expected_delivery,
           delivered_at, last_checked_at, next_check_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(
        s.id, s.deviceId, s.number, s.carrier, s.name ?? null, s.status, s.provider, s.providerRef ?? null,
        s.expectedDelivery ?? null, s.deliveredAt ?? null, s.lastCheckedAt ?? null, s.nextCheckAt ?? null,
        s.createdAt, s.updatedAt,
      );
  }

  updateShipment(s: ShipmentRecord) {
    this.db
      .prepare(
        `UPDATE shipments SET name = ?, status = ?, provider_ref = ?, expected_delivery = ?, delivered_at = ?,
           last_checked_at = ?, next_check_at = ?, updated_at = ? WHERE id = ?`,
      )
      .run(
        s.name ?? null, s.status, s.providerRef ?? null, s.expectedDelivery ?? null, s.deliveredAt ?? null,
        s.lastCheckedAt ?? null, s.nextCheckAt ?? null, s.updatedAt, s.id,
      );
  }

  getShipment(id: string): ShipmentRecord | undefined {
    const row = this.db.prepare("SELECT * FROM shipments WHERE id = ?").get(id) as Record<string, any> | undefined;
    return row ? toShipment(row) : undefined;
  }

  findShipment(deviceId: string, number: string): ShipmentRecord | undefined {
    const row = this.db
      .prepare("SELECT * FROM shipments WHERE device_id = ? AND number = ?")
      .get(deviceId, number) as Record<string, any> | undefined;
    return row ? toShipment(row) : undefined;
  }

  findByProviderRef(provider: string, ref: string): ShipmentRecord[] {
    const rows = this.db
      .prepare("SELECT * FROM shipments WHERE provider = ? AND provider_ref = ?")
      .all(provider, ref) as Record<string, any>[];
    return rows.map(toShipment);
  }

  listShipments(deviceId: string): ShipmentRecord[] {
    const rows = this.db
      .prepare("SELECT * FROM shipments WHERE device_id = ? ORDER BY created_at DESC")
      .all(deviceId) as Record<string, any>[];
    return rows.map(toShipment);
  }

  countActiveShipments(deviceId: string): number {
    const row = this.db
      .prepare("SELECT COUNT(*) AS n FROM shipments WHERE device_id = ? AND status != 'delivered'")
      .get(deviceId) as { n: number };
    return Number(row.n);
  }

  dueShipments(now: string, limit = 100): ShipmentRecord[] {
    const rows = this.db
      .prepare("SELECT * FROM shipments WHERE next_check_at IS NOT NULL AND next_check_at <= ? ORDER BY next_check_at LIMIT ?")
      .all(now, limit) as Record<string, any>[];
    return rows.map(toShipment);
  }

  deleteShipment(id: string) {
    this.db.prepare("DELETE FROM shipments WHERE id = ?").run(id);
  }

  /** Löscht zugestellte Sendungen, deren Zustellung vor `before` liegt. */
  purgeDelivered(before: string): number {
    const result = this.db.prepare("DELETE FROM shipments WHERE delivered_at IS NOT NULL AND delivered_at < ?").run(before);
    return Number(result.changes);
  }

  // MARK: Ereignisse

  /** Fügt neue Ereignisse ein (Duplikate werden ignoriert) und liefert die Anzahl neuer Einträge. */
  addEvents(shipmentId: string, events: TrackingEvent[]): number {
    const statement = this.db.prepare(
      "INSERT OR IGNORE INTO events (shipment_id, occurred_at, text, location, status) VALUES (?, ?, ?, ?, ?)",
    );
    let added = 0;
    for (const e of events) {
      added += Number(statement.run(shipmentId, e.date, e.text, e.location ?? null, e.status).changes);
    }
    return added;
  }

  events(shipmentId: string): TrackingEvent[] {
    const rows = this.db
      .prepare("SELECT occurred_at, text, location, status FROM events WHERE shipment_id = ? ORDER BY occurred_at DESC")
      .all(shipmentId) as Record<string, any>[];
    return rows.map((r) => ({
      date: r.occurred_at,
      text: r.text,
      location: r.location ?? undefined,
      status: r.status as ShipmentStatus,
    }));
  }
}

function toShipment(row: Record<string, any>): ShipmentRecord {
  return {
    id: row.id,
    deviceId: row.device_id,
    number: row.number,
    carrier: row.carrier as Carrier,
    name: row.name ?? undefined,
    status: row.status as ShipmentStatus,
    provider: row.provider,
    providerRef: row.provider_ref ?? undefined,
    expectedDelivery: row.expected_delivery ?? undefined,
    deliveredAt: row.delivered_at ?? undefined,
    lastCheckedAt: row.last_checked_at ?? undefined,
    nextCheckAt: row.next_check_at ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
