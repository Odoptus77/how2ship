# Paketlotse – App-Konzept

*Version 1.0 · Stand: 30.09.2026*
*Grundlage: [Marktrecherche](marktrecherche.md) (Wettbewerb, App-Markt, Monetarisierung, Namensprüfung)*

---

## 1. Überblick

**Paketlotse ist der Versandberater für Privatkunden in Deutschland.** Du misst dein Paket mit der Kamera oder gibst die Maße ein. Die App zeigt dir alle passenden Tarife von DHL, Deutsche Post, Hermes, DPD, GLS und UPS, sagt dir, wie du noch günstiger versendest, und bringt dich zum Buchen. Danach verfolgst du deine Sendungen direkt in der App.

**Slogan:** *„Dein Paket. Der beste Weg.“*
**Titel im App Store:** *Paketlotse – Paketpreise vergleichen*

### Was uns von anderen unterscheidet

| Paketlotse | Wettbewerb |
|---|---|
| **Kamera-Vermessung für alle Paketdienste** | DHL (Packset) und Hermes: nur für die eigenen Formate |
| **Neutraler Vergleich** mit guter Bedienung | Versandpreis und PortoCheck: klein, veraltet, keine Buchung |
| **Formatberatung**, z. B. „2 cm kürzer und du sparst 2,10 €“ | Andere Rechner zeigen nur Preislisten |
| **Vergleichen, Buchen und Verfolgen in einer App** | Tracking-Apps (Parcello u. a.) vergleichen keine Preise |
| Echte App mit Kamera, Karte und Push-Benachrichtigungen | Packlink: keine Endkunden-App |

### Rahmen
- **Markt:** nur Deutschland. Absender in Deutschland, zunächst nur Empfänger im Inland. Ziele im Ausland folgen in einer späteren Phase.
- **Branche:** nur KEP (Kurier-, Express- und Paketdienste), keine branchenfremden Partnerprogramme.
- **Zielgruppe:** Privatkunden (B2C)
- **Grundsatz:** Der Vergleich ist neutral und immer nach dem Gesamtpreis sortiert.

---

## 2. Zielgruppe und Personas

| Persona | Situation | Was sie braucht |
|---|---|---|
| **Lena, 29, Gelegenheitsversenderin** | Verschickt 2- bis 3-mal im Monat Geschenke, Retouren, Kleinanzeigen-Verkäufe | Schnell wissen, wo es am günstigsten ist, und wie sie das Paket abgibt |
| **Thomas, 54, unsicherer Versender** | Weiß nicht, ob Päckchen oder Paket, und misst ungern | Kamera-Vermessung und klare Empfehlung („Nimm DHL Päckchen M“) |
| **Aylin, 35, Hobby-Verkäuferin** | Verkauft selbstgemachte Sachen, 15 bis 40 Pakete im Monat | Gespeicherte Paketgrößen, Verlauf, Sendungsübersicht, später Labels in der App |

---

## 3. Funktionsumfang

### 3.1 Überblick nach Phasen

| # | Funktion | Phase 1 (MVP) | Phase 2 | Phase 3 |
|---|---|:-:|:-:|:-:|
| F1 | Maße und Gewicht manuell eingeben | ✅ | | |
| F2 | **Kamera-Vermessung** (AR, alle Paketdienste) | ✅ | | |
| F3 | **Tarif-Rechner** mit den Messregeln aller Paketdienste | ✅ | | |
| F4 | Ergebnisliste mit Filtern | ✅ | | |
| F5 | **Formatberatung** („Spar-Tipp“) | ✅ | | |
| F6 | „Jetzt buchen“ als Deep-Link bzw. Affiliate-Link | ✅ | | |
| F7 | **Sendungsverfolgung** | ✅ | ✅ automatisch | |
| F8 | Karte mit Paketshops und Packstationen | ✅ | | |
| F9 | Premium (werbefrei und Komfortfunktionen) | ✅ | | |
| F10 | **Label-Kauf in der App** | | ✅ | |
| F11 | Adressbuch | | ✅ | |
| F12 | Ziele im Ausland (von Deutschland aus) | | ✅ | |
| F13 | Hervorgehobene Paketshops | | | ✅ |
| F14 | Direkte Anzeigen von Paketdiensten | | | ✅ |

### 3.2 F1 und F2: Paket erfassen

**Manuelle Eingabe**
- Länge, Breite und Höhe in cm, Gewicht in kg
- Schnellauswahl: „Schuhkarton“, „Weinflasche“, „Brief-dick“ usw.
- Premium: eigene gespeicherte Paketgrößen („Mein Standardkarton“)

**Kamera-Vermessung**
- Auf dem iPhone per ARKit, auf Geräten mit LiDAR (Tiefensensor) noch genauer. Auf Android per ARCore.
- Ablauf:
  1. Karton auf eine ebene Fläche stellen.
  2. Mit der Kamera die Ecken antippen oder automatisch erkennen lassen.
  3. Die App zeigt L × B × H an.
- **Sicherheitsaufschlag:** Gemessene Werte werden um 1 cm aufgerundet. Liegt ein Wert nahe an einer Formatgrenze, erscheint der Hinweis „Knapp an der Grenze: bitte nachmessen“.
- Das Kamerabild wird **nur auf dem Gerät** verarbeitet, nichts wird hochgeladen (Datenschutz-Vorteil).
- Die Kamera-Vermessung ist **kostenlos und unbegrenzt**, es gibt kein Kontingent.
- Gewicht: bleibt eine manuelle Eingabe. Der Hinweis „Keine Waage? Nimm eine Küchen- oder Personenwaage“ hilft, ergänzt um Schätzhilfen.

### 3.3 F3: Tarif-Rechner

Der Kern der App. Die Paketdienste rechnen nach unterschiedlichen Regeln:

| Paketdienst | Maßgebliche Messregel |
|---|---|
| DHL / Deutsche Post | Gewichtsklassen plus Höchstmaße je Produkt (Päckchen, Paket, Kleinpaket, Warensendung) |
| Hermes | Summe aus längster und kürzester Seite (Größen S, M, L …), dazu ein Höchstgewicht |
| DPD | Summe aus längster und kürzester Seite (Größenklassen) |
| GLS | Summe aus längster und kürzester Seite (Größenklassen) |
| UPS | Volumengewicht (L × B × H ÷ Divisor) oder tatsächliches Gewicht, je nachdem, was höher ist |

**Umsetzung:**
- Jeder Paketdienst wird als **Regelwerk in JSON** beschrieben: Produkte, Grenzen, Preise, Vertriebsweg (online oder Filiale), Haftung, Zusatzleistungen.
- Der Rechner läuft **auf dem Gerät**. So funktioniert er ohne Internet und liefert sofort ein Ergebnis.
- Die Tarifdaten sind versioniert (`tarife-2026.1.json`). Der Server liefert Updates, und die App zeigt den Stand an („Preise Stand 01.01.2026“).
- Unterschieden wird zwischen **Online-Preis und Filialpreis**. Standard ist der günstigste Weg, der für Privatkunden verfügbar ist.

### 3.4 F4: Ergebnisliste

- Sortiert nach **Gesamtpreis** (Standard), wahlweise nach Laufzeit oder Haftung
- Jede Zeile zeigt: Logo, Produktname, **Preis**, Laufzeit, Haftung bzw. Versicherung, Abgabeoptionen (Paketshop, Packstation, Abholung) und die Hinweise „Online-Frankierung“ bzw. „Filiale“
- **Badges:** „Günstigster“, „Schnellster“, „Beste Haftung“
- **Filter:** Abholung ab Haustür, Packstation, Sendungsverfolgung, Haftung ab X €
- **Transparenz-Hinweis** unter der Liste: „Sortiert nach Gesamtpreis. Bei manchen Buchungen erhalten wir eine Provision, die Reihenfolge beeinflusst das nicht.“

### 3.5 F5: Formatberatung („Spar-Tipp“)

Die App prüft automatisch, ob eine kleine Änderung ein günstigeres Format ermöglicht:
- *„Wenn dein Paket 2 cm kürzer ist (48 statt 50 cm), passt es in Hermes S. Du sparst 2,10 €.“*
- *„Unter 1 kg? Dann geht auch das DHL Päckchen S für 4,19 € statt 6,19 €.“* (Beispielwerte)
- *„Wertvoller Inhalt? Die Haftung bei X liegt nur bei 50 €. Nimm Y mit 500 €.“*

Ein Spar-Tipp erscheint nur, wenn er realistisch ist, zum Beispiel bei höchstens 3 cm oder 0,5 kg Abweichung.

### 3.6 F6: „Jetzt buchen“

Neben jedem Tarif steht ein Button, der den Nutzer zur Buchung bringt:
- **Mit Provision:** Ist ein Portal mit Partnerprogramm (Packlink, Eurosender) am günstigsten oder gleich teuer, führt der Button per Affiliate-Link dorthin.
- **Ohne Provision:** Ist die Online-Frankierung beim Paketdienst selbst am günstigsten, führt der Button direkt zum Paketdienst.
- Die Buchung öffnet sich **im In-App-Browser** (SFSafariViewController bzw. Chrome Custom Tabs). Ist die App des Paketdienstes installiert, öffnet sich stattdessen diese.
- Die App merkt sich die Buchung als **„offene Buchung“**. Das ist der Auslöser für F7, siehe Abschnitt 4.

### 3.7 F8: Karte mit Paketshops und Packstationen

- Zeigt Abgabestellen des gewählten Paketdienstes in der Nähe, mit Öffnungszeiten und Entfernung.
- Filter: „Jetzt geöffnet“, „Sonntags geöffnet“, „Packstation / Paketautomat“
- Die Standorte kommen aus den Standort-APIs der Paketdienste, sofern verfügbar, sonst aus eigener Datenpflege bzw. OpenStreetMap.
- Ab Phase 3 können sich Paketshops hervorheben lassen (F13), als „Anzeige“ gekennzeichnet.

### 3.8 F9: Premium

| Kostenlos | Premium (2,99 € einmalig) |
|---|---|
| Vergleich, Kamera-Vermessung, Spar-Tipps | ✔ |
| Sendungsverfolgung inkl. Push-Benachrichtigungen | ✔ |
| Karte mit Abgabestellen | ✔ |
| Dezente Banner | **Werbefrei** |
| Sendungsverlauf der letzten 30 Tage | **Unbegrenzter Versandverlauf und Kostenübersicht** („2026: 34 Pakete, 187 € Porto“) |
| – | **Gespeicherte Paketgrößen** |
| – | **Preisalarm** bei Tarifänderungen |
| – | **Adressbuch** (ab Phase 2) |

---

## 4. Sendungsverfolgung (F7)

**Ziel:** Nach der Buchung bleibt der Nutzer in Paketlotse. Er sieht den Status aller Sendungen an einem Ort und wird bei jedem Schritt benachrichtigt.

**Nutzen für das Geschäft:** Die Sendungsverfolgung verwandelt eine App, die man einmal im Monat öffnet, in eine App, die man mehrmals pro Woche öffnet. Das stärkt die Bindung, bringt mehr Werbeeinblendungen und macht die App beim nächsten Versand wieder zur ersten Wahl.

### 4.1 Wie die Sendungsnummer in die App kommt

**Phase 1 (Buchung über Deep-Link oder Affiliate-Link, extern):** Die Buchung passiert außerhalb der App, deshalb kennt Paketlotse die Nummer nicht automatisch. Es gibt fünf Wege, sie hineinzubekommen:

| # | Weg | Ablauf |
|---|---|---|
| 1 | **Rückkehr-Abfrage** | Kommt der Nutzer aus dem Buchungsbrowser zurück, fragt die App: *„Hast du gebucht? Füge jetzt die Sendungsnummer hinzu und wir halten dich auf dem Laufenden.“* |
| 2 | **Erinnerung** | Nach 2 Stunden und am nächsten Morgen kommt eine lokale Benachrichtigung zur offenen Buchung: *„Dein Hermes-Paket: Sendungsnummer hinzufügen?“* |
| 3 | **Barcode-Scan** | Die Kamera scannt das Versandlabel oder den Einlieferungsbeleg aus dem Paketshop. Die Nummer wird aus dem Barcode (Code 128, DataMatrix, QR) gelesen, der Paketdienst wird erkannt. |
| 4 | **Zwischenablage** | Wurde eine Sendungsnummer kopiert, bietet die App an, sie einzufügen. Auf iOS läuft das über die System-Abfrage zum Einfügen. |
| 5 | **Teilen bzw. Share-Extension** | Aus einer Buchungsbestätigung per E-Mail oder PDF: „Teilen → Paketlotse“. Die App liest die Nummer aus dem Text. |

Zusätzlich lassen sich **eingehende Sendungen** manuell hinzufügen, also Pakete, die der Nutzer selbst erwartet. Das kostet keinen Mehraufwand und erhöht die Nutzung.

**Phase 2 (Label-Kauf in der App):** Die Sendungsnummer kommt **automatisch** mit dem Label. Die Verfolgung startet ohne Zutun des Nutzers.

### 4.2 Paketdienst automatisch erkennen

- Das Format der Nummer wird per Regex geprüft, gegebenenfalls mit Prüfziffer. Beispiele: UPS beginnt mit `1Z…`. DHL nutzt meist 12 bis 20 Ziffern bzw. `JJD…`. Hermes, DPD und GLS haben eigene Längen und Präfixe.
- Ist das Ergebnis nicht eindeutig, fragt die App kurz nach: „Welcher Paketdienst?“. Aus der offenen Buchung ist der Paketdienst meist schon bekannt.
- Der Nutzer kann der Sendung einen Namen geben, z. B. „Geschenk für Oma“.

### 4.3 Anzeige und Benachrichtigungen

- **Tab „Sendungen“:** Liste mit Status-Chips (Unterwegs, In Zustellung, Zugestellt, Problem)
- **Detailansicht:** Zeitleiste mit allen Ereignissen, voraussichtliches Zustelldatum, Button „Beim Paketdienst öffnen“ für Umleitung und Ablageort
- **Push-Benachrichtigungen** bei Statuswechseln, standardmäßig nur bei wichtigen Ereignissen: eingeliefert, in Zustellung, zugestellt, Problem
- **iOS Live Activity bzw. Android-Widget:** „Dein Paket ist heute in Zustellung“ auf dem Sperrbildschirm
- **Automatisches Archivieren** 7 Tage nach Zustellung. In der kostenlosen Version wird die Sendung **30 Tage nach Zustellung gelöscht**, in Premium bleibt sie im Verlauf.

### 4.4 Technische Umsetzung

| Option | Paketdienste | Kosten | Einsatz |
|---|---|---|---|
| **DHL Shipment Tracking – Unified API** | DHL und Deutsche Post | kostenlos. Zum Start 250 Abfragen pro Tag, Erhöhung auf Anfrage | direkt für DHL |
| **Tracking-Anbieter** (Ship24, TrackingMore, 17TRACK, AfterShip) | Hermes, DPD, GLS, UPS und über 1.000 weitere | z. B. Ship24 ca. 39 $ pro 1.000 Sendungen. TrackingMore ab 11 $ im Monat, darüber ca. 0,04 $ pro Sendung | alle anderen Paketdienste, mit Webhooks (Server ruft uns bei Statuswechsel auf) |
| Direkte APIs der Paketdienste (Hermes, DPD, GLS, UPS) | jeweils einer | meist nur für Geschäftskunden | später, zur Kostensenkung |

**Ablauf:**
1. Die App meldet die Sendungsnummer beim Paketlotse-Server an.
2. Der Server registriert die Sendung beim Tracking-Anbieter bzw. fragt bei DHL ab.
3. Der Tracking-Anbieter meldet Statuswechsel per Webhook (bei DHL fragt der Server in Intervallen ab, z. B. alle 2 bis 4 Stunden, oder nutzt die DHL-Push-API).
4. Der Server schickt eine Push-Nachricht an die App (APNs bzw. FCM).

**Kosten:** Mit ca. 0,03 bis 0,04 € pro Sendung ist die Verfolgung **für alle Nutzer kostenlos**. Die Kosten werden durch Provision und Werbung gedeckt. Pro Nutzer gibt es eine Obergrenze, um Missbrauch zu verhindern, z. B. 30 aktive Sendungen.

**Datenschutz:**
- Gespeichert werden nur Sendungsnummer, Paketdienst, Name der Sendung, Statushistorie und ein Push-Token.
- **Keine Empfängeradressen** in Phase 1.
- Die Verbindung zum Konto läuft über eine anonyme Geräte-ID. Ein Login ist optional (nötig für die Synchronisierung über mehrere Geräte bzw. für Premium).
- Die Tracking-Anbieter sind Auftragsverarbeiter nach Art. 28 DSGVO, mit Auftragsverarbeitungsvertrag (AVV). Anbieter mit Hosting in der EU werden bevorzugt.
- Die Daten werden nach Ablauf automatisch gelöscht (siehe 4.3).

---

## 5. Nutzerfluss

```
┌─────────────┐   ┌──────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│ 1. Paket    │──▶│ 2. Ergebnisliste │──▶│ 3. Jetzt buchen │──▶│ 4. Zurück in App │
│  erfassen   │   │  + Spar-Tipp     │   │  (In-App-Browser│   │  „Sendungsnummer │
│ Kamera/Hand │   │  + Karte         │   │   / Carrier-App)│   │   hinzufügen?“   │
└─────────────┘   └──────────────────┘   └─────────────────┘   └────────┬─────────┘
                                                                        ▼
                  ┌──────────────────┐   ┌─────────────────┐   ┌──────────────────┐
                  │ 7. Zugestellt ✔  │◀──│ 6. Push bei     │◀──│ 5. Scan / Einfügen│
                  │  → Verlauf,      │   │  Statuswechsel, │   │  / Teilen →      │
                  │  nächster Versand│   │  Live Activity  │   │  Tracking aktiv  │
                  └──────────────────┘   └─────────────────┘   └──────────────────┘
```

---

## 6. Navigation und Bildschirme

**Tab-Leiste (4 Tabs):**

| Tab | Inhalt |
|---|---|
| 📦 **Versenden** | Startbildschirm: großer Button „Paket vermessen“ und Maßeingabe, darunter Schnellauswahl und die zuletzt verwendeten Größen |
| 🚚 **Sendungen** | Aktive und zugestellte Sendungen, Button „+ Sendung hinzufügen“ (Scan, Einfügen, manuell) |
| 📍 **Karte** | Paketshops und Packstationen in der Nähe |
| 👤 **Profil** | Premium, Versandverlauf und Kosten (Premium), gespeicherte Größen, Benachrichtigungen, Datenschutz, „So vergleichen wir“ |

**Wichtige Bildschirme:**
1. **Onboarding** mit 3 Seiten: „Vermessen, Vergleichen, Verfolgen“. Dann die Abfrage für Push-Benachrichtigungen, erst beim ersten Tracking, nicht sofort.
2. **Kamera-Vermessung:** AR-Ansicht mit Anleitung, Ergebnis-Overlay und dem Button „Übernehmen“
3. **Ergebnisliste** mit Karte für den Spar-Tipp ganz oben
4. **Tarif-Detail:** Maße, Grenzen, Haftung, Abgabeoptionen, „Jetzt buchen“
5. **Sendung hinzufügen:** Scanner, Einfügen, manuelle Eingabe
6. **Sendungsdetail:** Zeitleiste, voraussichtliche Zustellung, Link zum Paketdienst
7. **Premium-Seite**

**Design:** klar und vertrauenswürdig. Primärfarbe z. B. Navy bzw. Petrol („Lotse“, maritim), Akzentfarbe Orange für Buttons. Die Logos der Paketdienste werden nur so verwendet, wie die jeweiligen Markenrichtlinien es erlauben. Unterstützt Dark Mode, große Schrift und VoiceOver bzw. TalkBack.

---

## 7. Monetarisierung

*Details und Beispielrechnung: siehe Marktrecherche, Abschnitt 9.*

| Einnahmequelle | Phase | Wo in der App |
|---|---|---|
| **A. Provision** (Packlink, Eurosender u. a.) | 1 | Button „Jetzt buchen“, nur beim günstigsten oder gleich teuren Angebot |
| **B. Premium 2,99 € einmalig** | 1 | Profil, dazu ein sanfter Hinweis im Verlauf und bei gespeicherten Größen |
| **C. Werbung** (Banner) | 1 | Unter der Ergebnisliste und in der Sendungsliste. **Keine Vollbild-Werbung, keine Werbung in der Kamera-Ansicht.** |
| **D. Label-Kauf** (Marge 0,50 bis 1,50 € pro Label) | 2 | Direkt in der Ergebnisliste. Bezahlung per PayPal, Apple Pay oder Karte, außerhalb des Store-Bezahlsystems (Apple-Richtlinie 3.1.5) |
| **E. Hervorgehobene Paketshops** | 3 | Karte, als „Anzeige“ gekennzeichnet |
| **F. Direkte Anzeigen von Paketdiensten** | 3 | Anzeigefläche über bzw. unter der Liste, **ohne Einfluss auf das Ranking** |

**Beitrag der Sendungsverfolgung:** Sie ist kostenlos, bringt aber:
- mehr App-Öffnungen, damit mehr Werbeeinblendungen und mehr Wiederkehr zum Vergleich
- ein stärkeres Argument für Premium (unbegrenzter Verlauf, Kostenübersicht)

Sie **kostet** ca. 0,03 bis 0,04 € pro Sendung. Das ist durch A und C gedeckt.

---

## 8. Technische Architektur

```
┌──────────────────────── App (Flutter) ─────────────────────────┐
│  UI  ·  Tarif-Engine (offline, JSON-Regeln)  ·  Barcode-Scan   │
│  AR-Modul: ARKit (iOS, nativ) / ARCore (Android, nativ)        │
│  Lokale DB (Sendungen, Größen)  ·  Ads-SDK  ·  In-App-Kauf     │
└──────────────┬─────────────────────────────────────────────────┘
               │ HTTPS
┌──────────────▼──────────── Backend (EU-Hosting) ───────────────┐
│  API (Tarif-Updates, Sendungen, Affiliate-Links)               │
│  Tracking-Service ──▶ DHL Unified API / Ship24-TrackingMore    │
│        ▲ Webhooks                                              │
│  Push-Service ──▶ APNs / FCM                                   │
│  Admin: Tarifpflege, Affiliate-Konfiguration, Paketshop-Daten  │
└────────────────────────────────────────────────────────────────┘
```

| Baustein | Empfehlung | Begründung |
|---|---|---|
| App | **Flutter** (eine Codebasis für iOS und Android) | Schnelle Entwicklung, gute Kamera- und Barcode-Plugins |
| AR-Vermessung | Native Module (ARKit mit LiDAR bzw. ARCore) über Platform Channels | Beste Genauigkeit, kein Kompromiss durch plattformübergreifende AR |
| Barcode-Scan | Google ML Kit bzw. Apple Vision | Offline, schnell, kostenlos |
| Backend | Supabase oder Firebase (Region EU) mit Serverless Functions | Wenig Betriebsaufwand, Auth, Datenbank und Push aus einer Hand |
| Tarifdaten | Versionierte JSON-Dateien mit Admin-Oberfläche und Tests je Tarif | Ohne App-Update aktualisierbar, Fehler werden früh erkannt |
| Karten | Apple Maps / Google Maps SDK, Standortdaten der Paketdienste bzw. OpenStreetMap | Standard |
| Tracking | DHL Unified API und ein Tracking-Anbieter mit Webhooks | Kosten nur pro Sendung |
| Analytics | Datenschutzfreundlich (z. B. PostHog EU, Telemetry Deck) | DSGVO |

### Datenmodell (vereinfacht)

```
Tarif          { carrier, produkt, kanal(online|filiale), preis, gueltig_ab,
                 regel{typ: gewicht|summe_laengste_kuerzeste|volumengewicht,
                       grenzen{…}}, max_gewicht, haftung, laufzeit }
Paket          { l, b, h, gewicht, quelle(kamera|manuell), name? }
Buchung        { id, tarif_ref, zeitpunkt, status(offen|nummer_erfasst|verworfen),
                 affiliate_partner? }
Sendung        { id, nummer, carrier, name?, richtung(ausgehend|eingehend),
                 status, ereignisse[], erwartete_zustellung?, buchung_ref?,
                 erstellt, zugestellt_am?, loeschen_am }
Nutzer         { geraete_id, push_token, premium(bool), login? }
```

---

## 9. Rechtliches und Compliance

| Thema | Umsetzung |
|---|---|
| **Ranking-Transparenz (§ 5b UWG)** | Seite „So vergleichen wir“ plus Kurzhinweis unter jeder Ergebnisliste |
| **Werbekennzeichnung (§ 5a UWG)** | „Anzeige“ bzw. „Partner-Link“ sichtbar an Werbung und Affiliate-Buttons |
| **Preisangaben (PAngV)** | Endpreise inkl. Mehrwertsteuer, Tarifstand, Hinweis auf mögliche Zuschläge |
| **DSGVO und TTDSG** | Einwilligungs-Management (CMP) für Werbung, Tracking-Abfrage auf iOS (ATT), Auftragsverarbeitungsverträge mit Tracking- und Backend-Anbietern, Datenminimierung und Löschfristen (siehe 4.4) |
| **Markenrechte der Paketdienste** | Logos nur nach deren Markenrichtlinien, keine Anmutung einer offiziellen Partnerschaft, Hinweis „Paketlotse ist ein unabhängiger Vergleichsdienst“ |
| **Haftung für Tarife** | Hinweis „Alle Angaben ohne Gewähr, maßgeblich sind die Bedingungen des Paketdienstes“ |
| **Markenschutz Paketlotse** | Domains `.de`, `.com`, `.app` sichern, DPMA-Wortmarke in Klasse 9, 35, 39 anmelden (siehe Marktrecherche 10.6) |

---

## 10. Roadmap

| Phase | Zeitraum | Inhalte | Meilenstein |
|---|---|---|---|
| **0. Vorbereitung** | Monat 0 bis 1 | Domains, Marke, Konten. Tarif-Datenbank der 6 Paketdienste, Landingpage mit Warteliste, 20 Nutzerinterviews | 500 Anmeldungen auf der Warteliste |
| **1. MVP** | Monat 1 bis 4 | F1 bis F9: Vergleich, Kamera-Vermessung, Spar-Tipps, Buchen-Button, Sendungsverfolgung, Karte, Premium, Werbung | Veröffentlichung in App Store und Google Play |
| **1b. Optimierung** | Monat 4 bis 6 | Store-Optimierung (ASO), Onboarding, Anteil der Nummern, die nach der Buchung erfasst werden, Genauigkeit der Kamera-Vermessung | 10.000 Downloads |
| **2. Label-Kauf** | Monat 6 bis 18 | F10 bis F12: Label-Kauf über Zwischenhändler, automatische Sendungsverfolgung, Adressbuch, Ziele im Ausland | Label-Verkauf als Hauptumsatz |
| **3. Ausbau** | ab Monat 18 | F13, F14: Paketshop-Einträge, Kooperationen mit Paketdiensten, Abo testen | Profitabler Betrieb |

---

## 11. Kennzahlen

| Kennzahl | Ziel Jahr 1 |
|---|---|
| Downloads | 30.000 |
| Aktive Nutzer pro Monat | 8.000 |
| Vergleiche pro aktivem Nutzer und Monat | ≥ 1,5 |
| Anteil Kamera-Vermessungen | ≥ 40 % der Vergleiche |
| Klicks auf „Jetzt buchen“ | ≥ 15 % der Vergleiche |
| Buchungen mit Provision | ≥ 3 % der Vergleiche |
| **Sendungsnummer nach Buchung erfasst** | ≥ 35 % der Buchungs-Klicks |
| **Aktive Sendungen pro Nutzer und Monat** | ≥ 1 |
| **Nutzer, die nach 30 Tagen wiederkommen** | ≥ 25 % (dank Sendungsverfolgung) |
| Premium-Kaufquote | ≥ 2 % der Downloads |
| Bewertung im App Store | ≥ 4,5 ★ |

---

## 12. Risiken und offene Fragen

| Risiko bzw. Frage | Gegenmaßnahme |
|---|---|
| Kamera-Vermessung ungenau, Nutzer müssen am Schalter nachzahlen | Aufschlag von 1 cm, Warnung nahe an Formatgrenzen, Hinweis zum Nachmessen, Feedback-Button |
| Tarife veralten | Versionierte Tarife, jährlicher Tarif-Check plus Benachrichtigung bei Änderungen, Nutzer können Fehler melden |
| Wenige Sendungsnummern werden nach externer Buchung erfasst | Fünf Wege der Erfassung (4.1), Erinnerung, einfacher Scan. Löst sich mit Phase 2 von selbst. |
| Tracking-Kosten steigen mit der Nutzung | Obergrenze aktiver Sendungen, DHL über die kostenlose API, direkte APIs der Paketdienste prüfen |
| DHL-Tracking-Kontingent (250 Abfragen pro Tag zum Start) | Rechtzeitig eine Erhöhung beantragen, abgestuftes Abfragen, Push-API nutzen |
| Paketdienste zahlen keine Provision | Schwerpunkt auf Phase 2 (Label-Marge), direkte Kooperationen anfragen |
| Marktplätze übernehmen den Versand (Vinted u. a.) | Schwerpunkt auf freiem Privatversand und Hobby-Verkäufern, eingehende Sendungen verfolgen |
| **Offen:** Welcher Label-Zwischenhändler für Phase 2? | Konditionen von Packlink-API, Eurosender-API und Label-Anbietern mit Rahmenverträgen vergleichen |
| **Offen:** Standortdaten der Paketshops (Lizenz) | Nutzungsbedingungen der APIs der Paketdienste bzw. OpenStreetMap prüfen |

---

## Quellen (ergänzend zur Marktrecherche)
- DHL Shipment Tracking – Unified API: https://developer.dhl.com/tracking
- DHL Tracking API kostenlos, Kontingent: https://support-developer.dhl.com/support/solutions/articles/47001249492-is-the-dhl-shipment-tracking-unified-api-free-of-charge-
- DHL Tracking Push-API: https://developer.dhl.com/api-reference/shipment-tracking-unified-push
- Vergleich von Tracking-APIs 2026 (Ship24): https://www.ship24.com/blog/best-shipment-tracking-api
- TrackingMore-Alternativen und Preise: https://www.ship24.com/blog/trackingmore-alternatives
- AfterShip-Preise: https://www.ship24.com/shops/aftership-tracking
- 17TRACK-Preise: https://www.ship24.com/shops/17track-tracking
