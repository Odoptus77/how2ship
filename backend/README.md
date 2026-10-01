# Paketlotse – Backend für die Sendungsverfolgung

Node.js 22 + TypeScript + Fastify, Datenbank SQLite (`node:sqlite`, ohne native Abhängigkeiten).

**Aufgaben:** Sendungen der App entgegennehmen, bei Tracking-Anbietern abfragen bzw. Webhooks empfangen, Status normalisieren, bei Statuswechsel Push an die App (APNs), alte Daten löschen.

```
App ──HTTPS──▶ API (/v1/shipments …)
                 │
                 ├─▶ DHL Unified Tracking API (DHL / Deutsche Post, Abfrage alle 1–3 h)
                 ├─▶ Ship24 (Hermes, DPD, GLS, UPS) ◀── Webhook /v1/webhooks/ship24
                 └─▶ APNs ──▶ Push „Heute in Zustellung“, „Zugestellt“ …
```

## Schnellstart (lokal, mit simulierten Sendungen)
```bash
cd backend
npm install
USE_MOCK_PROVIDER=true npm run dev        # http://localhost:8787
npm test                                   # 17 Tests
```
Mit dem **Mock-Anbieter** durchläuft jede Sendung in ca. 6 Minuten alle Stufen bis „zugestellt“. Nummern, die auf `X` enden, landen in „Problem“. So lässt sich die App komplett ohne API-Keys testen.

## API
Authentifizierung ohne Konto: Die App sendet `X-Device-Id: <UUID>` und `Authorization: Bearer <Geheimnis ≥ 32 Zeichen>`. Beim ersten Aufruf wird das Gerät angelegt, gespeichert wird nur ein Hash des Geheimnisses.

| Methode | Pfad | Zweck |
|---|---|---|
| GET | `/health` | Status, aktive Anbieter |
| PUT | `/v1/device/push-token` | `{ token, sandbox }` – Push-Token setzen (`null` = entfernen) |
| DELETE | `/v1/device` | Gerät und alle Daten löschen (DSGVO) |
| GET | `/v1/shipments` | alle Sendungen des Geräts |
| POST | `/v1/shipments` | `{ number, carrier, name? }` – anmelden |
| GET | `/v1/shipments/:id` | Details inkl. Ereignisse |
| POST | `/v1/shipments/:id/refresh` | sofort nachfragen (max. alle 5 min) |
| DELETE | `/v1/shipments/:id` | löschen |
| POST | `/v1/webhooks/ship24` | Updates von Ship24 (Bearer = `SHIP24_WEBHOOK_SECRET`) |

`carrier`: `dhl`, `deutschePost`, `hermes`, `dpd`, `gls`, `ups`. `status`: `registered`, `inTransit`, `outForDelivery`, `delivered`, `problem`. Das entspricht dem Datenmodell der App.

## Regeln
- **Abfrage-Intervalle:** angemeldet und unterwegs alle 3 h, in Zustellung jede Stunde, Problem alle 6 h, zugestellt gar nicht mehr. Bei Ship24 (Webhook) nur alle 12 h als Rückfallebene.
- **Push** nur bei relevanten Wechseln: unterwegs, in Zustellung, zugestellt, Problem.
- **Missbrauchsschutz:** max. 30 aktive Sendungen pro Gerät, Refresh max. alle 5 min.
- **Datensparsamkeit:** Gespeichert werden keine Namen, Adressen oder E-Mails. Zugestellte Sendungen werden nach 30 Tagen gelöscht.

## Produktivbetrieb
1. Keys besorgen:
   - **DHL:** developer.dhl.com → App anlegen → „Shipment Tracking – Unified“. Zum Start gibt es nur 250 Abrufe pro Tag, das Kontingent rechtzeitig erhöhen lassen.
   - **Ship24:** Konto und API-Key anlegen. Als Webhook-URL `https://<server>/v1/webhooks/ship24` mit Header `Authorization: Bearer <SHIP24_WEBHOOK_SECRET>` eintragen.
   - **APNs:** Apple Developer → Certificates, IDs & Profiles → Keys → neuer Key mit „Apple Push Notifications service“. Key-ID, Team-ID und den Inhalt der .p8-Datei als Umgebungsvariablen setzen. Dafür ist ein **kostenpflichtiger Apple-Developer-Account** nötig.
2. Deployen, z. B. per Docker auf einem kleinen Server (Hetzner, Fly.io, Render) mit persistentem Volume für `/data`:
   ```bash
   docker build -t paketlotse-backend .
   docker run -d -p 8787:8787 -v paketlotse-data:/data --env-file .env paketlotse-backend
   ```
   Davor einen HTTPS-Reverse-Proxy schalten (Caddy, Traefik) bzw. die HTTPS-Terminierung der Plattform nutzen.
3. In der App `API_BASE_URL` in `ios/Config/Secrets.xcconfig` auf die Server-URL setzen.

## Noch zu prüfen
- Das Antwortformat von Ship24 und DHL ist nach Dokumentation umgesetzt und mit Beispieldaten getestet. Beim ersten echten Key bitte mit echten Sendungen gegenprüfen.
- Ship24-Kurier-Codes für Hermes, DPD und GLS: Aktuell erkennt Ship24 den Paketdienst selbst.
- Für Ship24 fallen Kosten pro Sendung an. Siehe Konzept, Abschnitt 4.5.
