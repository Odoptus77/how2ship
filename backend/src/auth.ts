import { createHash, timingSafeEqual } from "node:crypto";
import type { Database } from "./db.js";

/**
 * Anonyme Geräte-Authentifizierung – ohne Konto, ohne personenbezogene Daten.
 * Die App erzeugt beim ersten Start eine Geräte-ID (UUID) und ein zufälliges Geheimnis (Keychain)
 * und schickt beide bei jeder Anfrage mit: `X-Device-Id` und `Authorization: Bearer <secret>`.
 * Der Server speichert nur einen Hash des Geheimnisses. Beim ersten Kontakt wird das Gerät angelegt.
 */
export function hashSecret(secret: string): string {
  return createHash("sha256").update(secret).digest("hex");
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type AuthResult = { ok: true; deviceId: string } | { ok: false; status: 400 | 401; message: string };

export function authenticate(
  db: Database,
  headers: Record<string, string | string[] | undefined>,
  now: string,
): AuthResult {
  const deviceId = String(headers["x-device-id"] ?? "").toLowerCase();
  const authorization = String(headers["authorization"] ?? "");
  const secret = authorization.startsWith("Bearer ") ? authorization.slice(7) : "";
  if (!UUID.test(deviceId) || secret.length < 32) {
    return { ok: false, status: 400, message: "X-Device-Id (UUID) und Bearer-Geheimnis (mind. 32 Zeichen) erforderlich" };
  }

  const hash = hashSecret(secret);
  const device = db.getDevice(deviceId);
  if (!device) {
    db.insertDevice(deviceId, hash, now);
    return { ok: true, deviceId };
  }
  const a = Buffer.from(device.secretHash, "hex");
  const b = Buffer.from(hash, "hex");
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    return { ok: false, status: 401, message: "Ungültiges Gerätegeheimnis" };
  }
  db.touchDevice(deviceId, now);
  return { ok: true, deviceId };
}
