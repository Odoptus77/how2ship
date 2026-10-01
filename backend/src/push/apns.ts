import { connect, type ClientHttp2Session } from "node:http2";
import { createPrivateKey, sign } from "node:crypto";
import type { Config } from "../config.js";

export interface PushMessage {
  title: string;
  body: string;
  /** Eigene Daten für die App, z. B. die Sendungs-ID. */
  data?: Record<string, string>;
}

export interface PushSender {
  send(deviceToken: string, message: PushMessage, sandbox: boolean): Promise<"sent" | "invalid-token" | "failed">;
}

/** Für Entwicklung/Tests: schreibt Nachrichten nur ins Log bzw. in eine Liste. */
export class LogPushSender implements PushSender {
  readonly sent: { token: string; message: PushMessage }[] = [];
  constructor(private readonly log: (line: string) => void = () => {}) {}
  async send(token: string, message: PushMessage) {
    this.sent.push({ token, message });
    this.log(`[push] ${token.slice(0, 8)}… ${message.title} – ${message.body}`);
    return "sent" as const;
  }
}

/**
 * Apple Push Notification service über HTTP/2 mit Token-Authentifizierung (.p8-Schlüssel, ES256-JWT).
 * Keine Fremdbibliothek nötig. Doku: https://developer.apple.com/documentation/usernotifications
 */
export class APNsSender implements PushSender {
  private jwt?: { token: string; issuedAt: number };
  private sessions = new Map<string, ClientHttp2Session>();

  constructor(private readonly config: NonNullable<Config["apns"]>) {}

  /** JWT ist max. 60 min gültig; Apple empfiehlt Erneuerung alle 20–60 min. */
  private authToken(): string {
    const now = Math.floor(Date.now() / 1000);
    if (this.jwt && now - this.jwt.issuedAt < 50 * 60) return this.jwt.token;
    const header = base64url(JSON.stringify({ alg: "ES256", kid: this.config.keyId }));
    const payload = base64url(JSON.stringify({ iss: this.config.teamId, iat: now }));
    const signature = sign("sha256", Buffer.from(`${header}.${payload}`), {
      key: createPrivateKey(this.config.privateKey),
      dsaEncoding: "ieee-p1363",
    });
    const token = `${header}.${payload}.${base64url(signature)}`;
    this.jwt = { token, issuedAt: now };
    return token;
  }

  private session(sandbox: boolean): ClientHttp2Session {
    const host = sandbox || !this.config.production ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
    const existing = this.sessions.get(host);
    if (existing && !existing.closed && !existing.destroyed) return existing;
    const session = connect(host);
    session.on("error", () => this.sessions.delete(host));
    session.on("close", () => this.sessions.delete(host));
    this.sessions.set(host, session);
    return session;
  }

  async send(deviceToken: string, message: PushMessage, sandbox: boolean) {
    const payload = JSON.stringify({
      aps: { alert: { title: message.title, body: message.body }, sound: "default", "thread-id": "shipments" },
      ...message.data,
    });
    return new Promise<"sent" | "invalid-token" | "failed">((resolve) => {
      try {
        const request = this.session(sandbox).request({
          ":method": "POST",
          ":path": `/3/device/${deviceToken}`,
          authorization: `bearer ${this.authToken()}`,
          "apns-topic": this.config.bundleId,
          "apns-push-type": "alert",
          "apns-priority": "10",
          "content-type": "application/json",
        });
        let status = 0;
        let body = "";
        request.on("response", (headers) => (status = Number(headers[":status"])));
        request.on("data", (chunk) => (body += chunk));
        request.on("end", () => {
          if (status === 200) return resolve("sent");
          // 400 BadDeviceToken / 410 Unregistered → Token verwerfen
          if (status === 410 || /BadDeviceToken|Unregistered/.test(body)) return resolve("invalid-token");
          resolve("failed");
        });
        request.on("error", () => resolve("failed"));
        request.setTimeout(10_000, () => {
          request.close();
          resolve("failed");
        });
        request.end(payload);
      } catch {
        resolve("failed");
      }
    });
  }

  close() {
    for (const session of this.sessions.values()) session.close();
  }
}

function base64url(input: string | Buffer): string {
  return Buffer.from(input).toString("base64url");
}
