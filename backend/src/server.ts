import Fastify, { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { timingSafeEqual } from "node:crypto";
import { authenticate } from "./auth.js";
import type { Config } from "./config.js";
import type { Database } from "./db.js";
import { isCarrier } from "./model.js";
import { parseShip24Tracking } from "./providers/ship24.js";
import { ServiceError, type TrackingService } from "./tracking-service.js";

declare module "fastify" {
  interface FastifyRequest {
    deviceId: string;
  }
}

export interface ServerDeps {
  config: Config;
  db: Database;
  service: TrackingService;
  providerNames: string[];
  logger?: boolean;
}

/**
 * REST-API für die iOS-App.
 *
 *   GET    /health
 *   PUT    /v1/device/push-token        { token, sandbox }   Push-Token setzen (null = entfernen)
 *   DELETE /v1/device                                        Gerät und alle Daten löschen (DSGVO)
 *   GET    /v1/shipments                                     alle Sendungen des Geräts
 *   POST   /v1/shipments                { number, carrier, name? }
 *   GET    /v1/shipments/:id
 *   POST   /v1/shipments/:id/refresh                         beim Anbieter nachfragen (max. alle 5 min)
 *   DELETE /v1/shipments/:id
 *   POST   /v1/webhooks/ship24                               Statusupdates von Ship24
 */
export function buildServer(deps: ServerDeps): FastifyInstance {
  const { db, service, config } = deps;
  const app = Fastify({ logger: deps.logger ?? false, bodyLimit: 1_000_000 });

  app.decorateRequest("deviceId", "");

  app.setErrorHandler((error: Error & { statusCode?: number; validation?: unknown }, _request, reply) => {
    if (error instanceof ServiceError) return reply.code(error.statusCode).send({ error: error.message });
    if (error.validation) return reply.code(400).send({ error: error.message });
    app.log.error(error);
    return reply.code(500).send({ error: "Interner Fehler" });
  });

  app.get("/health", async () => ({ ok: true, providers: deps.providerNames, push: Boolean(config.apns) }));

  // Webhook: eigene Authentifizierung über das mit Ship24 vereinbarte Geheimnis.
  app.post("/v1/webhooks/ship24", async (request, reply) => {
    const expected = config.ship24WebhookSecret;
    const given = String(request.headers.authorization ?? "").replace(/^Bearer /, "");
    if (!expected || !safeEqual(given, expected)) return reply.code(401).send({ error: "Nicht autorisiert" });

    const trackings: any[] = (request.body as any)?.trackings ?? [];
    let matched = 0;
    for (const tracking of trackings) {
      const trackerId = tracking?.tracker?.trackerId;
      if (!trackerId) continue;
      matched += await service.applyWebhook("ship24", trackerId, parseShip24Tracking(tracking));
    }
    return { received: trackings.length, matched };
  });

  // Alle /v1-Routen außer Webhooks erfordern ein authentifiziertes Gerät.
  app.register(async (scope) => {
    scope.addHook("preHandler", async (request: FastifyRequest, reply: FastifyReply) => {
      const result = authenticate(db, request.headers, new Date().toISOString());
      if (!result.ok) return reply.code(result.status).send({ error: result.message });
      request.deviceId = result.deviceId;
    });

    scope.put(
      "/v1/device/push-token",
      {
        schema: {
          body: {
            type: "object",
            properties: { token: { type: ["string", "null"], maxLength: 200 }, sandbox: { type: "boolean" } },
            required: ["token"],
          },
        },
      },
      async (request) => {
        const { token, sandbox } = request.body as { token: string | null; sandbox?: boolean };
        if (token !== null && !/^[0-9a-fA-F]{32,200}$/.test(token)) throw new ServiceError("Ungültiger Push-Token", 400);
        db.updatePushToken(request.deviceId, token, sandbox ?? false);
        return { ok: true };
      },
    );

    scope.delete("/v1/device", async (request, reply) => {
      db.deleteDevice(request.deviceId);
      return reply.code(204).send();
    });

    scope.get("/v1/shipments", async (request) => ({ shipments: service.list(request.deviceId) }));

    scope.post(
      "/v1/shipments",
      {
        schema: {
          body: {
            type: "object",
            properties: {
              number: { type: "string", minLength: 4, maxLength: 60 },
              carrier: { type: "string" },
              name: { type: "string", maxLength: 80 },
            },
            required: ["number", "carrier"],
          },
        },
      },
      async (request, reply) => {
        const { number, carrier, name } = request.body as { number: string; carrier: string; name?: string };
        if (!isCarrier(carrier)) throw new ServiceError("Unbekannter Paketdienst", 400);
        const shipment = await service.register(request.deviceId, number, carrier, name);
        return reply.code(201).send(shipment);
      },
    );

    scope.get("/v1/shipments/:id", async (request) => {
      const { id } = request.params as { id: string };
      return service.get(request.deviceId, id);
    });

    scope.post("/v1/shipments/:id/refresh", async (request) => {
      const { id } = request.params as { id: string };
      return service.refresh(request.deviceId, id);
    });

    scope.delete("/v1/shipments/:id", async (request, reply) => {
      const { id } = request.params as { id: string };
      service.remove(request.deviceId, id);
      return reply.code(204).send();
    });
  });

  return app;
}

function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
