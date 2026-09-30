# Paketlotse – iOS-App (Swift / SwiftUI)

Native iOS-App, ab iOS 17. Die Geschäftslogik liegt im Swift-Package **PaketlotseCore** und ist mit Unit-Tests abgedeckt. Die App selbst ist nur die Oberfläche in SwiftUI.

## Voraussetzungen
- Mac mit **Xcode 15.3 oder neuer** (für Swift 5.10)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Loslegen
```bash
git clone <repo> && cd how2ship
git checkout claude/how2ship-market-research-ockdkg
cd ios
xcodegen generate            # erzeugt Paketlotse.xcodeproj aus project.yml
open Paketlotse.xcodeproj    # Simulator wählen (z. B. iPhone 15) → ⌘R
```
Die `.xcodeproj` wird nicht eingecheckt. Nach neuen oder umbenannten Dateien einfach erneut `xcodegen generate` ausführen.

**Tests der Kernlogik** (Tarifrechner, Spar-Tipps, Sendungsnummern, Abfrage-Regeln):
```bash
cd ios/PaketlotseCore && swift test
```
Alternativ `Package.swift` in Xcode öffnen und dort ⌘U drücken.

## Aufbau
```
ios/
├── project.yml                      XcodeGen-Spezifikation
├── PaketlotseCore/                  Swift-Package (plattformunabhängige Logik)
│   ├── Sources/PaketlotseCore/
│   │   ├── ParcelDimensions.swift   Maße, Messregeln (längste + kürzeste Seite, Volumengewicht)
│   │   ├── Carrier.swift            Paketdienste, Tracking-Links
│   │   ├── Tariff.swift             Tarif-Regelwerk + Katalog (JSON)
│   │   ├── ShippingRequirements     Zusatzleistungen, Aufpreise, Versicherung
│   │   ├── TariffEngine.swift       Vergleich: passende Tarife, sortiert nach Preis, Badges
│   │   ├── SavingsAdvisor.swift     Spar-Tipp („2 cm kürzer → 0,69 € sparen“)
│   │   ├── TrackingNumberDetector   Sendungsnummer erkennen / normalisieren / aus Text extrahieren
│   │   ├── Booking.swift            Offene Buchung + Abfrage-Regeln (60 s, 48 h, Erinnerungen)
│   │   ├── Shipment.swift           Sendung, Status, Ereignisse
│   │   ├── BoxMeasurement.swift     Rechenlogik der Kamera-Vermessung (Punkte → L × B × H)
│   │   ├── Locations/               Abgabestellen: Modell, DHL- & Overpass-Parser, OSM-Öffnungszeiten
│   │   └── Resources/tarife-beispiel.json   ⚠️ BEISPIELPREISE
│   └── Tests/PaketlotseCoreTests/
└── Paketlotse/                      App (SwiftUI)
    ├── App/                         Einstieg, Tabs, Benachrichtigungs-Delegate
    ├── Theme/                       Farben, Schrift (SF Rounded), Carrier-Farben
    ├── Components/                  Karten, Chips, Tags, Hero-Banner, Buttons
    ├── Services/                    AppStore (Zustand), Persistenz, Erinnerungen
    └── Features/
        ├── Home/                    Maße eingeben, Schnellauswahl, Zusatzleistungen
        ├── Measure/                 Kamera-Vermessung (ARKit + SceneKit)
        ├── Results/                 Ergebnisliste, Spar-Tipp, „Jetzt buchen“, „So vergleichen wir“
        ├── Shipments/               Sendungen, Abfrage der Sendungsnummer, Barcode-Scanner
        ├── Map/                     Karte mit Abgabestellen, Filtern, Detailkarte, Route
        ├── Premium/                 Paywall, Versandverlauf & Kostenübersicht
        └── Profile/                 Premium-Status, gespeicherte Größen, Tarifstand, Rechtliches
```

## Design
Orientiert an der Referenz „Job Finder UI Kit“:
- heller, blaugrauer Hintergrund (`#E9F2F6`), weiße Karten mit weichem Schatten und 24 pt Radius
- Petrol als Primärfarbe (`#1F6E8C`), Orange als Akzent (`#F2A93B`), Creme für Hinweiskarten (Spar-Tipp)
- Pill-Chips, runde Avatare je Paketdienst, SF Rounded
- Dark Mode ist über dynamische Farben in `Theme.swift` vorbereitet

## Stand (v0.1)
| Funktion | Status |
|---|---|
| Maße und Gewicht eingeben, Schnellauswahl | ✅ |
| Tarifvergleich mit den Messregeln aller Paketdienste | ✅ (Beispielpreise) |
| Spar-Tipp, Hinweis „knapp an der Grenze“, Badges | ✅ |
| Zusatzleistungen (Versicherung mit Warenwert, Sendungsverfolgung, Abholung, Unterschrift, Packstation) im Preis und als Filter | ✅ (Beispielpreise) |
| „Jetzt buchen“: öffnet extern, merkt sich die offene Buchung | ✅ |
| **Abfrage der Sendungsnummer** bei Rückkehr (ab 60 s, bis 48 h, einmalig) | ✅ |
| Eintippen, Einfügen (PasteButton), Barcode-Scan (VisionKit) | ✅ |
| Erinnerungen nach 2 h und am nächsten Morgen um 9 Uhr, „Nicht gebucht“ | ✅ |
| Sendungsliste und Detailansicht, Link zum Paketdienst | ✅ |
| **Kamera-Vermessung** (ARKit, Scene Depth auf LiDAR-Geräten): 3 Bodenecken + Deckel, Live-Wert, Sicherheitsaufschlag, Plausibilitätsprüfung | ✅ nur auf echtem iPhone |
| Automatischer Tracking-Status und Push (Backend) | ⏳ |
| **Paketshop-Karte** mit echten Standorten: DHL Location Finder (optional, API-Key) + OpenStreetMap für Hermes/DPD/GLS/UPS; Filter nach Paketdienst, Automaten, „Jetzt geöffnet“; Route | ✅ |
| **Premium** (StoreKit 2, Einmalkauf 2,99 €): Paywall, Kaufen/Wiederherstellen, gespeicherte Paketgrößen, Versandverlauf & Kostenübersicht, unbegrenzter Sendungsverlauf | ✅ |
| Werbung, Affiliate-Links | ⏳ |

## Paketshop-Karte
- **Ohne Einrichtung** lädt die Karte Standorte aus **OpenStreetMap**, über die Overpass API und ohne Key. Das deckt DHL-Packstationen, Postfilialen sowie Hermes-, DPD-, GLS- und UPS-Shops ab, soweit sie in OSM erfasst sind.
- **Optional mit offiziellen DHL-Daten** (inkl. Öffnungszeiten):
  1. Auf https://developer.dhl.com ein Konto anlegen, eine App erstellen und die API **„Location Finder – Unified“** hinzufügen. Der Key ist kostenlos.
  2. `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` ausführen und den Key eintragen. Die Datei wird nicht eingecheckt.
  3. `xcodegen generate` ausführen und die App neu bauen.
- Die Standort-Freigabe ist optional. Ohne Freigabe verschiebt man die Karte selbst und tippt auf „In diesem Bereich suchen“.
- **Für den Produktivbetrieb:** Ein API-Key in der App ist auslesbar. Außerdem sind die öffentlichen Overpass-Server nicht für viele Nutzer gedacht. Beide Abfragen sollten später über das Paketlotse-Backend laufen, mit Cache. Die Quellenangabe „© OpenStreetMap-Mitwirkende“ ist Pflicht (ODbL) und bereits eingebaut.

## Kamera-Vermessung testen
- Funktioniert **nur auf einem echten iPhone**, nicht im Simulator. Dort erscheint ein Hinweis.
- iPhone per Kabel anschließen, in Xcode unter *Signing & Capabilities* dein Team auswählen, Gerät als Ziel wählen, dann ⌘R.
- Ablauf: Karton auf den Boden stellen, iPhone kurz bewegen, drei untere Ecken mit + setzen, dann auf den Deckel zielen. Mit „Übernehmen“ landen die Werte in den Eingabefeldern.
- Die Werte enthalten 1 cm Sicherheitsaufschlag und sind auf ganze cm aufgerundet.

## Premium (StoreKit 2) testen
- **Lokal ohne App Store Connect:** Das Schema nutzt `StoreKit/Paketlotse.storekit`. Einfach im Simulator oder auf dem Gerät starten, Profil → „Jetzt freischalten“. Der Kauf wird simuliert.
- Käufe zurücksetzen: in Xcode *Debug → StoreKit → Manage Transactions…* und die Transaktion löschen.
- „Kaufen anfragen“, Fehler oder Erstattungen lassen sich dort ebenfalls simulieren.
- **Für TestFlight und App Store:**
  1. In App Store Connect unter *Verträge* das Paid-Apps-Agreement abschließen, inklusive Bank- und Steuerdaten.
  2. Einen In-App-Kauf vom Typ **Nicht-verbrauchbar** mit der Produkt-ID `de.paketlotse.app.premium` und 2,99 € anlegen, mit Anzeigename, Beschreibung und Screenshot für die Prüfung.
  3. Die Produkt-ID muss mit `PurchaseManager.premiumProductID` übereinstimmen.
- **Was Premium freischaltet:** gespeicherte Paketgrößen (Startbildschirm → „Größe speichern“), den Versandverlauf mit Kosten pro Jahr (Profil) und einen unbegrenzten Sendungsverlauf. Werbefrei ist über `purchases.showsAds` vorbereitet, eine Werbe-SDK gibt es noch nicht.

## App-Icon
Variante B (Kartenpin mit Paket) ist im Asset-Katalog eingebaut, inklusive Dark- und Tinted-Variante (iOS 18+). Alle Einzelgrößen, die SVG-Quellen und ein ZIP liegen in `design/appicon/` (siehe `GROESSEN.md`).

## Wichtig vor einem Release
- **Tarife:** `tarife-beispiel.json` enthält **Platzhalterpreise**. Vor dem Release mit den offiziellen Preislisten abgleichen und `isSample` auf `false` setzen.
- **Sendungsnummern:** Die Muster in `TrackingNumberDetector` sind Heuristiken und müssen mit echten Sendungsnummern geprüft werden. Dasselbe gilt für die Tracking-URLs in `Carrier.swift`.
- **Logos:** Markenlogos der Paketdienste nur gemäß deren Richtlinien verwenden. Aktuell zeigt die App neutrale Farb-Avatare.

## Nächste Schritte
1. In Xcode bauen, im Simulator testen, Kompilierfehler beheben. Der Code wurde ohne Xcode geschrieben und ist noch **nicht kompiliert**.
2. Echte Tarifdaten der 6 Paketdienste einpflegen.
3. Kamera-Vermessung auf echten Geräten testen (mit und ohne LiDAR) und die Genauigkeit gegen einen Zollstock prüfen
4. Backend: Sendungen registrieren (DHL Unified API und Tracking-Anbieter), Webhooks, Push über APNs
5. StoreKit 2 für Premium, Affiliate-Links je Tarif
