/** Konfiguration ausschließlich über Umgebungsvariablen (siehe .env.example). */
export interface Config {
  port: number;
  host: string;
  databasePath: string;
  /** Tracking-Anbieter */
  dhlApiKey?: string;
  ship24ApiKey?: string;
  /** Geheimnis, das Ship24 beim Webhook-Aufruf als Bearer-Token mitschickt. */
  ship24WebhookSecret?: string;
  /** Mock-Anbieter erzwingen (Entwicklung/Tests) – sonst nur, wenn kein echter Anbieter konfiguriert ist. */
  useMockProvider: boolean;
  /** APNs (Push) */
  apns?: {
    keyId: string;
    teamId: string;
    bundleId: string;
    /** Inhalt der .p8-Datei (PEM) */
    privateKey: string;
    production: boolean;
  };
  /** Intervall des Abfrage-Jobs in Sekunden. */
  pollIntervalSeconds: number;
  /** Max. gleichzeitig verfolgte Sendungen pro Gerät (Missbrauchsschutz). */
  maxActiveShipmentsPerDevice: number;
  /** Zugestellte Sendungen werden nach X Tagen gelöscht (Datensparsamkeit). */
  retentionDaysAfterDelivery: number;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const apnsKey = env.APNS_PRIVATE_KEY?.replace(/\\n/g, "\n");
  return {
    port: Number(env.PORT ?? 8787),
    host: env.HOST ?? "0.0.0.0",
    databasePath: env.DATABASE_PATH ?? "./data/paketlotse.sqlite",
    dhlApiKey: env.DHL_API_KEY || undefined,
    ship24ApiKey: env.SHIP24_API_KEY || undefined,
    ship24WebhookSecret: env.SHIP24_WEBHOOK_SECRET || undefined,
    useMockProvider: env.USE_MOCK_PROVIDER === "true",
    apns:
      env.APNS_KEY_ID && env.APNS_TEAM_ID && env.APNS_BUNDLE_ID && apnsKey
        ? {
            keyId: env.APNS_KEY_ID,
            teamId: env.APNS_TEAM_ID,
            bundleId: env.APNS_BUNDLE_ID,
            privateKey: apnsKey,
            production: env.APNS_PRODUCTION === "true",
          }
        : undefined,
    pollIntervalSeconds: Number(env.POLL_INTERVAL_SECONDS ?? 300),
    maxActiveShipmentsPerDevice: Number(env.MAX_ACTIVE_SHIPMENTS ?? 30),
    retentionDaysAfterDelivery: Number(env.RETENTION_DAYS ?? 30),
  };
}
