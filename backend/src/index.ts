import { loadConfig } from "./config.js";
import { Database } from "./db.js";
import { Poller } from "./poller.js";
import { ProviderRegistry } from "./providers/index.js";
import { APNsSender, LogPushSender, type PushSender } from "./push/apns.js";
import { buildServer } from "./server.js";
import { TrackingService } from "./tracking-service.js";

const config = loadConfig();
const log = (line: string) => console.log(`${new Date().toISOString()} ${line}`);

const db = new Database(config.databasePath);
const providers = ProviderRegistry.fromConfig(config);
const push: PushSender = config.apns ? new APNsSender(config.apns) : new LogPushSender(log);
const service = new TrackingService(db, providers, push, config, () => new Date(), log);
const poller = new Poller(db, service, config.pollIntervalSeconds, log);
const app = buildServer({ config, db, service, providerNames: providers.names, logger: true });

log(`[start] Anbieter: ${providers.names.join(", ") || "keine"} · Push: ${config.apns ? "APNs" : "nur Log"}`);
if (providers.names.includes("mock")) log("[start] ⚠️ Mock-Anbieter aktiv – Sendungen werden simuliert.");

await app.listen({ port: config.port, host: config.host });
poller.start();

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, async () => {
    poller.stop();
    await app.close();
    if (push instanceof APNsSender) push.close();
    db.close();
    process.exit(0);
  });
}
