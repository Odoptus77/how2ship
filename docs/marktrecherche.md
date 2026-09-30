# how2ship / how2send – Marktrecherche

*Stand: 30.09.2026*

**Idee:** Ein Vergleichsportal für KEP-Dienstleister, ähnlich wie idealo. Nutzer geben Maße und Gewicht ihres Pakets ein und sehen alle passenden Angebote von DHL, Hermes, DPD, GLS, UPS usw.

---

## 1. Kurzfazit

| Frage | Antwort |
|---|---|
| Gibt es das schon? | **Ja, sogar mehrfach.** In Deutschland gibt es mindestens 8 bis 10 aktive Paketpreisvergleiche. Einige davon sind reine Rechner, andere buchen auch direkt. Der größte Anbieter (Packlink) gehört zu einem US-Konzern. |
| Sind die Namen frei? | **Nicht eindeutig.** `how2ship.com` und `how2send.com` sind registriert. Unter „How2ship“ gibt es eine US-Spedition (HOW2SHIP LLC). Unter „how2send“ habe ich keine aktive Marke oder Firma gefunden. `.de`, `.eu`, `.app` und `.io` haben keine DNS-Einträge, das beweist aber nicht, dass sie frei sind (siehe Abschnitt 3). |
| Gibt es Potenzial? | **Als reiner Preisvergleich kaum.** Der Markt ist voll, die Unterschiede zwischen den Anbietern sind klein, und Geld lässt sich damit schwer verdienen. **Potenzial besteht mit klarer Differenzierung**, siehe Abschnitt 5. |

---

## 2. Wettbewerb

### 2.1 Direkte Konkurrenz in Deutschland (Privat- und Gelegenheitsversender)

| Anbieter | Typ | Bemerkung |
|---|---|---|
| **Packlink** (packlink.de) | Vergleich und Buchung | Marktführer in Europa. Seit 2021 gehört Packlink zu Auctane (ShipStation, Stamps.com; Eigentümer ist Thoma Bravo). Wirbt mit „bis zu 70 % Ersparnis“ und hat ein Affiliate-Programm mit ca. 5 € pro Verkauf. |
| **paketda.de** | Preisrechner und Ratgeber | Unabhängig, stark bei SEO und mit großer Ratgeber-Community |
| **billigerverschicken.de** | Paket- und Briefrechner | Datenbank mit DHL, Hermes, DPD, UPS, Paket-AG und anderen |
| **paketcheck.com** | Tarifrechner | Eingabe genau wie in deiner Idee: Gewicht plus L×B×H, Vergleich von DHL, Hermes, DPD, GLS und UPS |
| **packager.de** | Tarifrechner | Maße per Schieberegler, zeigt die passenden Optionen |
| **shiparound.de** | Vergleichstabellen | Kostenlos, ohne Vertragsbindung |
| **LetMeShip, Eurosender, Europarcel, Parcel Monkey** | Vergleich und Buchung | Eher auf internationale Sendungen und KMU ausgerichtet |
| **Bundesnetzagentur** | Jährlicher Bericht „Paketpreisvergleich“ | Kein interaktives Tool, erhöht aber die Preistransparenz |

### 2.2 B2B-Versandsoftware (angrenzender Markt)

Sendcloud (über 160 Carrier), shipcloud (Hamburg), Packlink PRO, ShippyPro und nShift. Diese Anbieter bedienen Onlinehändler mit Schnittstellen zu Shopsystemen und Label-Druck. Hier sitzt das große Geld, aber auch die kapitalstarke Konkurrenz.

### 2.3 Internationale Vorbilder

- **Parcel2Go (UK):** 2001 gegründet, über 100 Mio. £ Umsatz, ca. 180 Mitarbeitende. Umsatz kommt aus Vergleich und Buchung, White-Label-Lösungen für Carrier und Palettenversand. **Das Modell funktioniert also grundsätzlich, allerdings mit über 20 Jahren Vorsprung.**
- **ParcelHero / ParcelCompare (UK)**, **Easyship**, **Shippo (US)**

### 2.4 Strukturelle Gegenwinde

- **Marktplätze übernehmen den Versand selbst:** Vinted bietet für neue Anzeigen seit dem 25.09.2026 keinen individuellen Versand mehr an. Bestehende Anzeigen mit individuellem Versand werden am 08.10.2026 auf integrierte Anbieter wie DHL umgestellt. Kleinanzeigen und eBay gehen einen ähnlichen Weg. Damit fällt genau das C2C-Segment weg, das einen Vergleich am dringendsten bräuchte.
- **Die Carrier vergleichen selbst transparent:** Die Preise sind öffentlich, und die Online-Frankierung ist billiger als die Filiale. Das Ersparnis-Potenzial beim Vergleich liegt für Privatleute oft bei nur 1 bis 3 €.
- **DHL, Hermes und Co. zahlen in der Regel keine Vermittlungsprovision.** Geld verdient man nur, wenn man Labels weiterverkauft (dafür braucht man eigene Rahmenverträge oder einen Konsolidierer wie Packlink bzw. Paket-AG) oder über Affiliate-Programme anderer Portale.

---

## 3. Namensprüfung

### how2ship

- **how2ship.com ist registriert.** Die Domain löst auf AWS-Global-Accelerator-IPs auf (13.248.169.48, 76.223.54.146). Das ist typisch für Registrar-Parking oder Weiterleitungen. Ob sie zum Verkauf steht, ließ sich von hier aus nicht prüfen.
- **HOW2SHIP LLC:** Eine aktive US-Spedition und Broker in North Jackson, Ohio (USDOT 3024882, MC-36372). Sie hat ein Profil auf uShip.com, also in genau derselben Branche.
- Weitere Treffer sind Motorola „How2ship“ (Handelsdaten), eine alte Shareware und YouTube-Videos.
- **Risiko:** Eine Verwechslungsgefahr im Logistikumfeld besteht vor allem in den USA. In der EU habe ich per Websuche keine eingetragene Marke gefunden, das ersetzt aber keine Registerrecherche.

### how2send

- **how2send.com ist registriert** und läuft über Cloudflare. Eine aktive Website oder Firma dazu habe ich nicht gefunden.
- Bei der Websuche gab es keine relevanten Treffer (nur ein Arduino-Forum und eine Avaya-Doku-Seite). **Der Name ist deutlich „unbesetzter“ als how2ship.**

### Andere Endungen (DNS-Abfrage)

| Domain | DNS-Eintrag |
|---|---|
| how2ship.de / .eu / .app / .io | keiner |
| how2send.de / .eu / .app / .io | keiner |

Wenn kein DNS-Eintrag existiert, heißt das nur, dass die Domain nicht aktiv genutzt wird. **Sie kann trotzdem registriert sein.** Die Whois/RDAP-Abfrage und die Markenregister (DPMA, EUIPO) waren in dieser Umgebung per Netzwerk-Proxy gesperrt.

**Bitte manuell prüfen:**
1. `.de`: https://www.denic.de/service/whois-service
2. Andere Endungen: https://lookup.icann.org
3. Marken EU-weit: https://www.tmdn.org/tmview (Nizza-Klassen 39 Transport/Logistik, 35 Vermittlung, 42 Software, 9 Apps)
4. Deutsche Marken: https://register.dpma.de
5. App Stores sowie Instagram- und TikTok-Handles

### Einschätzung zu den Namen

- **Für:** Die Namen sind kurz, international verständlich und sagen, worum es geht.
- **Gegen:**
  - Die „2“ ist mündlich schwer zu vermitteln („how-two“, „how-to“ oder „how-zwei“?). Deshalb sollte man zusätzlich die Domains `howtoship` / `howtosend` sichern.
  - Deutsche Nutzer suchen auf Deutsch („Paket günstig versenden“). Der Name bringt daher kaum SEO-Vorteil.
- **Empfehlung:** **how2send** hat weniger Kollisionen. Falls how2ship bevorzugt wird, zuerst die Marke in der EU prüfen und anmelden.

---

## 4. Marktgröße Deutschland (KEP-Studie 2025, BPEX)

- **4,29 Mrd. Sendungen** im Jahr 2024 (+2,8 %)
- **27,6 Mrd. € Umsatz** (+4,1 %)
- **B2C macht 60 %** der Sendungen aus (+5,5 %), B2B ist rückläufig (-1,6 %)
- **Prognose:** 5,2 Mrd. Sendungen bis 2030 (+3,2 % pro Jahr)
- Die 5 großen Netze (DHL, Hermes, DPD, GLS, UPS) haben ca. 85 % Umsatzanteil

Der Markt ist also groß und wächst. Der Anteil, der **aktiv verglichen** wird (Privatleute und Kleinstgewerbe, die selbst frankieren), ist allerdings nur ein Bruchteil davon.

---

## 5. Potenzial – wo eine Nische liegen könnte

Ein weiterer Rechner nach dem Muster „Maße eingeben und Preisliste sehen“ bringt wenig Neues. Folgende Ansätze könnten how2ship/how2send unterscheiden:

1. **Das „how2“ ernst nehmen: Beratung statt nur Preisliste**
   - **Karton mit der Handykamera vermessen** (AR bzw. LiDAR). Achtung: DHL (Packset-App) und Hermes bieten AR bereits an, aber jeweils nur für ihre eigenen Formate. Neu wäre die Kombination aus Kamera-Vermessung und Vergleich über alle Anbieter hinweg (siehe Abschnitt 8).
   - **Formatgrenzen erkennen:** „Wenn du 2 cm kürzer packst, passt es in Hermes S und kostet 2,10 € weniger.“
   - Tipps zu Verpackung, Sperrgut, Versicherung und Haftungsgrenzen (z. B. DPD-Haftungsfalle)
   - Günstigste **Abgabestelle in der Nähe** mit Öffnungszeiten (Paketshop, Packstation, Abholung)

2. **Nischen, in denen Vergleiche wirklich Geld sparen**
   - Sperrgut und übergroße Pakete, Möbel, Fahrräder (Preisunterschiede von 20 bis 100 €)
   - Internationaler Versand (große Preisspannen)
   - Paletten und Speditionen für Kleinstgewerbe
   - Versand von Tieren, Reifen, Gepäck (Studierende, Umzüge)

3. **Kleingewerbe mit 10 bis 300 Paketen pro Monat** (Etsy-Verkäufer, Kleinanzeigen-Profis, Handwerker): Für Sendcloud sind sie zu klein, für den Filialpreis zu groß. Hier liegen die meisten Einsparungen und die höchste Zahlungsbereitschaft (Abo oder Marge pro Label).

### Mögliche Erlösmodelle (vom schnellsten zum lukrativsten)

| Modell | Aufwand | Marge |
|---|---|---|
| Affiliate (Packlink u. a., ca. 5 €/Sale) und Werbung | niedrig | niedrig, abhängig von Dritten |
| Label-Reselling über Konsolidierer oder White-Label-API | mittel | ca. 0,50 bis 3 € pro Paket |
| Eigene Carrier-Rahmenverträge und Label-Reselling | hoch (Volumen, Haftung, Zahlungsabwicklung) | höchste Marge |
| SaaS-Abo für Kleingewerbe | mittel | wiederkehrend |

---

## 6. Risiken

- Starke, kapitalkräftige Wettbewerber (Auctane/Packlink, Sendcloud)
- Marktplätze übernehmen den C2C-Versand (Vinted, Kleinanzeigen, eBay)
- Pflegeaufwand für die Tarife: Die Preise ändern sich meist jährlich, dazu kommen Zuschläge (Maut, Energie, Peak)
- Die Carrier zahlen für reine Vermittlung kaum Provision
- Hohe SEO-Konkurrenz bei „Paket versenden günstig“

---

## 7. Empfehlung und nächste Schritte

1. **Domains und Marke sichern** (bevorzugt how2send): `.de`, `.com` (anfragen), `.app` sowie `howtosend`. EU-Marke in Klasse 35/39/42 prüfen.
2. **Nische wählen**, statt einen weiteren generischen Rechner zu bauen. Vorschlag: App mit **Kamera-Vermessung und Formatoptimierung** für Privatleute. Später Ausbau zu einem **Tool für Kleingewerbe** mit Label-Kauf.
3. **MVP:** Eigene Tarif-Datenbank der 5 großen Carrier plus Kleinpaket/Päckchen, Maßeingabe, Ergebnisliste und Deep-Links bzw. Affiliate. Das lässt sich in wenigen Wochen umsetzen.
4. **Validieren:** Landingpage und Warteliste, 20 Interviews mit Kleingewerbe-Versendern. Kernfrage: „Würdest du 5 €/Monat oder 0,50 €/Label zahlen?“
5. Erst danach Kontakt zu Konsolidierern oder API-Anbietern für das Label-Reselling aufnehmen.

---

## 8. App-Markt (Nachtrag)

*Websuche vom 30.09.2026. Direkte Store-Abfragen waren per Proxy gesperrt, deshalb sind die Download-Zahlen nur teilweise bekannt.*

### 8.1 Vergleichs-Apps für Deutschland (am nächsten an how2ship/how2send)

| App | Plattform | Was sie kann | Einschätzung |
|---|---|---|---|
| **Versandpreis** (Mypaketkasten GmbH) | iOS und Android | Vergleicht DHL, GLS, Hermes und DPD, dazu Briefporto der Deutschen Post und eine Paketshop-Suche | **Der direkteste Konkurrent.** Nur ca. 5.000+ Downloads bei Google Play. Es ist ein Nebenprodukt eines Paketkasten-Händlers und hat keine Buchungsfunktion. |
| **PortoCheck** | nur iOS | Vergleicht DHL/Post, Hermes, DPD und GLS nach Maßen und Gewicht, Deutschland und EU | Hobby-Niveau mit 3,5 Sternen bei 2 Bewertungen und Werbung. Preise auf dem Stand von 08/2025. |
| **Eurosender Mobile** | iOS und Android | Angebote von über 100 Carriern, Buchung, Label in der App, Tracking | Neu (2026). Die erste echte Buchungs-App, allerdings mit Fokus auf internationale Sendungen und Gewerbekunden. |
| **Packlink** | Web und Shop-Plugins | Vergleich und Buchung | Soweit ich es finden konnte, gibt es **keine eigenständige Endkunden-App**. Packlink setzt auf Web und Plugins für Shopify, Wix usw. |

### 8.2 Apps der Paketdienste (indirekte Konkurrenz)

- **DHL Post & Paket** und **DHL Packset:** Frankierung, Packstation und **AR-Bestimmung der Paketgröße per Kamera**, aber nur für DHL.
- **Hermes Paket:** Paketschein, Paketshop-Suche und **AR-Paketgrößen-Rechner** (seit 2018), aber nur für Hermes.
- **DPD, GLS, UPS:** jeweils eigene Apps zum Versenden und Verfolgen, aber nur für die eigene Marke.

Die Paketdienste haben also gute Apps, **vergleichen aber naturgemäß nicht mit der Konkurrenz.**

### 8.3 Tracking-Apps (angrenzend, nicht direkt konkurrierend)

Parcello, Parcel, Paketverfolgung & Parcel Track, Tracker Parcel und weitere. Sie verfolgen Sendungen von über 100 bis 300 Anbietern, **bieten aber keinen Preisvergleich und keinen Versand an.** Eine mögliche Idee wäre ein späteres Zusatzfeature (Versenden und Verfolgen in einer App) oder eine Partnerschaft.

### 8.4 Internationale Vorbilder

| App | Markt | Bemerkung |
|---|---|---|
| **Parcel2Go** | UK | Eigene App für iOS und Android, 4,4 von 5 Sternen bei Trustpilot. Zeigt, wie eine erfolgreiche Vergleichs- und Buchungs-App aussieht. |
| **Parcel Monkey** | UK/EU (auch DE-Seite) | Web-Fokus, 3,8 von 5 Sternen bei Trustpilot |
| **Pirate Ship, Shippo, Easyship** | USA/international | Zielgruppe sind Kleingewerbe und Onlinehändler. Pirate Ship ist kostenlos und ohne Aufschlag, verdient sein Geld über Carrier-Konditionen. Das ist ein Vorbild für das Segment „Kleingewerbe“. |

### 8.5 Fazit App-Markt

- **Im App-Store ist die Lücke echt:** Es gibt in Deutschland **keine gut gemachte, anbieterübergreifende Vergleichs- und Buchungs-App für Privatleute und Kleingewerbe.** Die vorhandenen Vergleichs-Apps (Versandpreis, PortoCheck) sind klein, veraltet und ohne Buchung. Packlink hat keine Endkunden-App.
- **Die Konkurrenz sitzt woanders:** Endkunden nutzen die Apps der Paketdienste (DHL, Hermes) oder den eingebauten Versand der Marktplätze (Vinted, Kleinanzeigen). Die Hürde ist also nicht eine bessere Vergleichs-App, sondern **Nutzer von der DHL-App wegzuholen.**
- **USP-Chance:** **AR-Vermessung für alle Anbieter** (DHL und Hermes können das nur jeweils für sich), dazu „packe 2 cm kürzer und spare X €“, Paketshop-Finder, und später Label-Kauf und Tracking in einer App.
- **Store-Suchbegriffe** („Paket versenden“, „Porto“, „Versandkosten“) sind von den Paketdienst-Apps und Tracking-Apps belegt. Kleine Wettbewerber ranken schwach, **App Store Optimization (ASO) ist also machbar.**

---

## 9. Monetarisierungsmodell (nur KEP, Privatkunden in Deutschland)

**Rahmen:**
- Zielgruppe sind Privatpersonen in Deutschland, die gelegentlich Pakete verschicken.
- Alle Einnahmen kommen aus dem Paketversand selbst, also keine Partnerprogramme für Kartons, Umzüge usw.
- Kamera-Vermessung und Preisvergleich sind **unbegrenzt kostenlos**, ein Kontingent gibt es nicht.

### 9.1 Grundprinzip

> **Der Vergleich ist neutral und kostenlos. Geld verdient die App bei der Buchung, mit Komfortfunktionen und mit dezenter Werbung.**

Die Ergebnisliste ist **immer nach dem Gesamtpreis sortiert**. Provision und Werbung dürfen die Reihenfolge nie beeinflussen. Das ist die Grundlage für das Vertrauen der Nutzer und für die Bewertungen im App Store.

### 9.2 Einnahmequellen

| # | Einnahmequelle | Ab Phase | Preis bzw. Vergütung | Anteil am Umsatz (Ziel) |
|---|---|---|---|---|
| **A** | **Provision bei Buchung** über Versandportale (Packlink bis ca. 5 € pro Buchung, Eurosender 7 %) | 1 | ca. 1,50 bis 5 € pro Buchung | Phase 1: ca. 60 % |
| **B** | **how2send Premium**, einmaliger Kauf in der App | 1 | 2,99 € | ca. 20 % |
| **C** | **Werbung** in der kostenlosen Version: Banner und klar gekennzeichnete Anzeigen von Versandanbietern | 1 | nach Einblendung bzw. Festpreis pro Monat | ca. 20 % |
| **D** | **Eigener Label-Verkauf**: Das Versandlabel wird direkt in der App gekauft, über einen Zwischenhändler oder eine Versand-API | 2 | Marge ca. 0,50 bis 1,50 € pro Label | ab Phase 2 der Hauptumsatz |
| **E** | **Hervorgehobene Paketshops** auf der Karte | 3 | ca. 5 bis 15 € pro Monat und Shop | Zusatzeinnahme |

#### A. Provision bei Buchung
- Unter jedem Tarif steht ein Button **„Jetzt buchen“**:
  - Ist ein Versandportal mit Partnerprogramm günstiger oder gleich teuer, verlinkt der Button per Affiliate-Link dorthin. Die App erhält die Provision.
  - Ist der Paketdienst direkt am günstigsten (z. B. DHL online), verlinkt der Button ohne Provision direkt zum Paketdienst. Die Neutralität geht vor.
- Beim Start registrierst du dich bei den Partnerprogrammen über Netzwerke wie Awin, affilinet usw. Parallel dazu fragst du **direkt bei Hermes, DPD, GLS und UPS** nach Kooperationen.
- Die wichtigste Kennzahl ist der **Anteil der Vergleiche, die zu einer Buchung mit Provision führen**.

#### B. how2send Premium: 2,99 € einmalig
| Kostenlos | Premium |
|---|---|
| Preisvergleich aller Paketdienste | ✔ |
| Kamera-Vermessung (unbegrenzt) | ✔ |
| Karte mit Paketshops und Packstationen | ✔ |
| Dezente Banner | **Werbefrei** |
| – | **Gespeicherte Paketgrößen**, z. B. „Mein Schuhkarton“ |
| – | **Versandverlauf** mit allen Kosten des Jahres |
| – | **Preisalarm**, wenn ein Paketdienst die Preise ändert |
| – | **Adressbuch** für häufige Empfänger (wichtig ab Phase 2) |

- Die Freischaltung ist ein digitales Gut. Sie muss deshalb über den Kauf im App Store bzw. bei Google Play laufen. Die Gebühr beträgt 15 % über das Small Business Program bzw. die reduzierte Rate bei Google.
- Später kann ein Abo (z. B. 0,99 € im Monat) getestet werden. Zum Start ist ein Einmalkauf aber einfacher zu verkaufen.

#### C. Werbung
- **Programmatische Banner** (AdMob o. Ä.), nur in der kostenlosen Version und **nie als Vollbild vor der Ergebnisliste**.
- **Direkte Anzeigen von Versandanbietern** innerhalb des KEP-Bereichs. Beispiel: „Hermes: Jetzt 1 € sparen mit dem Code …“. Diese stehen als **„Anzeige“ gekennzeichnet** über oder unter der Liste und verändern nie die Reihenfolge der Ergebnisse. Das lohnt sich erst ab einer gewissen Reichweite, dafür aber mit einem Festpreis pro Monat.
- Für personalisierte Werbung braucht die App ein **Einwilligungs-Management**: auf iOS die Tracking-Abfrage (App Tracking Transparency, ATT), dazu das europäische Einwilligungs-Framework (IAB TCF).

#### D. Eigener Label-Verkauf (Phase 2)
- Der Nutzer bezahlt direkt in how2send per PayPal, Apple Pay oder Karte und erhält das Versandlabel oder einen QR-Code für den Paketshop.
- Umsetzung über einen **Zwischenhändler mit API** (z. B. Packlink- oder Eurosender-API, oder ein Label-Anbieter mit Rahmenverträgen). Später kommen eigene Verträge mit den Paketdiensten dazu, wenn das Volumen reicht.
- Die Versandleistung ist eine **physische Dienstleistung**. Sie darf deshalb **außerhalb** des App-Store-Bezahlsystems abgerechnet werden (Apple Guideline 3.1.5), es fallen also keine 15 % Store-Gebühr an.
- Das ist der **eigentliche Hebel**: Die Marge fällt bei jedem Paket an, egal über welchen Paketdienst.

#### E. Hervorgehobene Paketshops (Phase 3)
- Paketshops (Kioske, Tankstellen usw.) können sich auf der Karte hervorheben lassen, etwa mit Öffnungszeiten, Foto und „Auch sonntags geöffnet“.
- Das lohnt sich erst mit vielen Nutzern pro Stadt. Die Shops verdienen nur ca. 0,30 bis 0,60 € pro Paket und haben entsprechend wenig Budget.

### 9.3 Phasen

| Phase | Zeitraum | Funktionen | Einnahmen |
|---|---|---|---|
| **1. Start** | Monat 0 bis 6 | Vergleich, Kamera-Vermessung, Karte, Buchen-Button | A, B, C |
| **2. Buchung in der App** | Monat 6 bis 18 | Label-Kauf in der App, Adressbuch, Versandverlauf | D wird zur Haupteinnahme |
| **3. Ausbau** | ab Monat 18 | Paketshop-Einträge, Kooperationen mit Paketdiensten, Abo testen | E, direkte Anzeigen |

### 9.4 Beispielrechnung

> ⚠️ **Das sind Annahmen, keine Marktdaten.** Sie müssen mit echten Nutzerzahlen überprüft werden.

**Annahmen für Jahr 1:** 30.000 Downloads, im Schnitt 8.000 aktive Nutzer pro Monat, je 1,5 Vergleiche pro Monat, also 12.000 Vergleiche im Monat.

| Einnahmequelle | Rechnung | pro Jahr |
|---|---|---|
| A. Provision | 12.000 × 3 % Buchung mit Provision × 3 € × 12 Monate | ca. 13.000 € |
| B. Premium | 30.000 × 2 % Kaufquote × 2,99 € × 0,85 | ca. 1.500 € |
| C. Werbung | 8.000 × 1,5 × 3 Einblendungen × 1,50 € pro 1.000 × 12 Monate | ca. 650 € |
| **Summe Jahr 1** | | **ca. 15.000 €** |

**Mit Label-Verkauf (Phase 2):** Jeder Anteil der Vergleiche, der direkt in der App gebucht wird, bringt eine Marge. Bei 60.000 aktiven Nutzern pro Monat, 90.000 Vergleichen und 10 % Buchungen in der App sind das 9.000 Labels im Monat. Mit 1 € Marge ergibt das **ca. 108.000 € pro Jahr**, dazu kommen A bis C.

**Fazit:** Ohne Label-Verkauf bleibt die App ein Nebenprojekt. Das Geschäft entsteht mit **Phase 2**. Phase 1 dient vor allem dazu, Nutzer zu gewinnen und zu prüfen, ob die App angenommen wird.

### 9.5 Kosten (grob)
- Apple Developer: 99 $ pro Jahr, Google Play: 25 $ einmalig
- Server, Datenbank und Karten-API: ca. 20 bis 100 € pro Monat zum Start
- **Tarife aktuell halten:** Die Preise ändern sich jährlich, dazu kommen Zuschläge. Das kostet laufend Zeit. Plane pro Jahr eine Kontrollrunde plus eine Benachrichtigung bei Preisänderungen ein.
- Rechtliches: Impressum, Datenschutz, AGB, eventuell eine anwaltliche Prüfung (einmalig ca. 500 bis 1.500 €)

### 9.6 Rechtliche Leitplanken
- **Ranking offenlegen (§ 5b UWG):** Die App muss nennen, wonach sie sortiert (Gesamtpreis) und dass Affiliate-Provisionen anfallen können, die das Ranking **nicht** beeinflussen.
- **Werbung kennzeichnen (§ 5a UWG):** Affiliate-Links und Anzeigen sind klar als „Anzeige“ bzw. „Partner-Link“ gekennzeichnet.
- **Preise korrekt angeben (PAngV):** Es werden Endpreise inklusive Mehrwertsteuer angezeigt, dazu der Stand der Tarife („Preise Stand 01/2026“) und ein Haftungsausschluss für Zuschläge.
- **Datenschutz (DSGVO und TTDSG):** Einwilligung für Werbe-Tracking. Die Kamera-Bilder werden nur auf dem Gerät verarbeitet und nicht hochgeladen, das ist auch ein gutes Verkaufsargument.

### 9.7 Kennzahlen
| Kennzahl | Ziel Jahr 1 |
|---|---|
| Downloads | 30.000 |
| Aktive Nutzer pro Monat | 8.000 |
| Vergleiche pro aktivem Nutzer und Monat | ≥ 1,5 |
| Anteil Klicks auf „Buchen“ | ≥ 15 % |
| Anteil Buchungen mit Provision | ≥ 3 % aller Vergleiche |
| Premium-Kaufquote | ≥ 2 % der Downloads |
| App-Store-Bewertung | ≥ 4,5 ★ |

---

## 10. App-Name (Recherche)

*Stand: 30.09.2026. Methode: DNS-Abfrage für .de, .com und .app sowie eine Websuche nach Apps, Firmen und Marken mit gleichem Namen. Die Whois-Abfrage (DENIC) und die Markenregister (DPMA, EUIPO) waren per Proxy gesperrt und müssen noch geprüft werden.*

### 10.1 Kriterien
- **Deutsch und so geschrieben, wie man es spricht.** Man muss den Namen am Telefon oder im Gespräch weitergeben können, ohne ihn zu buchstabieren. Keine „2“, keine Anglizismen-Schreibweise.
- **„Paket“ oder „Porto“ im Namen.** Das hilft bei der Suche im App Store, weil diese Wörter genau das sind, was Nutzer eintippen.
- **Positiver Nutzen:** Der Name soll ausdrücken, dass die App führt, spart oder berät.
- **Als Marke eintragbar.** Rein beschreibende Namen wie „Paketvergleich“ lassen sich schwer schützen.
- **Keine Kollision** mit bestehenden Paket-, Versand- oder Tracking-Apps.

### 10.2 Bereits belegt (Domain aktiv)
paketpilot, paketfuchs, portofuchs, paketradar, paketmeister, paketguru, paketbutler, paketengel, paketfix, packpilot, packfix, paketly, paketo, versandfuchs, versandklar, schickfix, schickmal, sendwise, packwise, paketvergleich.de, versandlotse.de, versandkompass.de, paketheld.de, portoheld.de, paketsparer.de, portosparer.de

### 10.3 Kandidaten ohne DNS-Eintrag (.de, .com und .app) und ohne Treffer in der Websuche

| Name | Eindruck | Marke eintragbar? | Bemerkung |
|---|---|---|---|
| **Paketlotse** | „führt dich zum besten Versand“, seriös, deutsch | gut (bildhaft, nicht nur beschreibend) | **Empfehlung Nr. 1.** Keine App und keine Firma gefunden. „versandlotse.de“ ist belegt, deshalb auf Verwechslungsgefahr prüfen. |
| **Paketschlau** | „schlau sparen“, freundlich, zeigt den Nutzen | mittel („schlau“ ist leicht beschreibend) | **Nr. 2.** Klingt locker und nahbar, passt gut zur Zielgruppe Privatkunden. |
| **Paketkompass** | Orientierung, Beratung | gut | **Nr. 3.** „Kompass“ ist eine bekannte Marke für Wanderkarten, aber in einer anderen Branche. |
| Portoschlau | wie Paketschlau, „Porto“ passt aber weniger zu Paketdiensten ohne Porto (Hermes, DPD) | mittel | Alternative |
| Paketkenner | Kompetenz | gut | etwas nüchtern |
| Paketscout | Suche, Entdecken | **Risiko** | Scout24 (ImmoScout24, AutoScout24) geht bekanntermaßen gegen „…Scout“-Namen vor |
| Paketwahl, Versandwahl | beschreibend | schwach | schwer als Marke zu schützen |
| Versandheld | eingängig | mittel | paketheld.de und portoheld.de sind belegt, dadurch droht Verwechslung |
| Paketjoker, Schickschlau, Verschick | – | – | weniger passend bzw. wenig einprägsam |

**how2send** (Vergleich): .de und .app ohne DNS-Eintrag, .com ist belegt. Der Name ist international, aber für eine rein deutsche Zielgruppe schwächer. Die Schreibweise mit „2“ muss man erklären, und das Wort „Paket“ fehlt für die Store-Suche.

### 10.4 Empfehlung
1. **Paketlotse**, mit Store-Titel „Paketlotse – Paketpreise vergleichen“
2. **Paketschlau** als Alternative mit lockerem, sparorientiertem Auftreten
3. **Paketkompass** als Reserve

### 10.5 Vor der Entscheidung prüfen
1. DENIC-Whois für `.de`, ICANN Lookup für `.com`. Wenn kein DNS-Eintrag existiert, kann die Domain trotzdem registriert sein.
2. Marken in **DPMAregister** und **TMview** prüfen, in den Klassen 9 (Apps), 35 (Vermittlung, Werbung), 39 (Transport) und 42 (Software). Auch ähnliche Namen suchen (z. B. „Lotse“ bzw. „Versandlotse“).
3. App Store und Google Play nach dem Namen durchsuchen, ebenso Instagram-, TikTok- und Facebook-Handles.
4. Danach sofort die Domains `.de`, `.com` und `.app` sichern und eine deutsche Wortmarke anmelden (DPMA, ab 290 € für 3 Klassen). Eine EU-Marke ist später möglich.

---

## Quellen

- Packlink Preisvergleich: https://www.packlink.com/de-DE/paketversand-preisvergleich/
- Auctane übernimmt Packlink: https://www.postbranche.de/2021/12/30/auctane-uebernimmt-die-fuehrende-europaeische-versandplattform-packlink/
- Packlink Partnerprogramm: https://www.100partnerprogramme.de/p/packlink-de-17142/
- paketda Preisrechner: https://www.paketda.de/paket-preis-rechner.php
- paketda Versandportale: https://www.paketda.de/firmenkunden/versandportale-firmenkunden.html
- billigerverschicken.de: https://billigerverschicken.de/
- paketcheck Tarifrechner: https://www.paketcheck.com/tarifrechner
- packager.de: https://www.packager.de/de
- shiparound Vergleichstabelle: https://shiparound.de/uebersichtstabelle-vergleich-paket-preise/
- Versandlexikon Preisvergleich: https://www.versandlexikon.com/paketdienstleister-deutschland/paketversand-preisvergleich
- LetMeShip: https://www.letmeship.com/shipping-software/shipping-calculator/
- Europarcel: https://europarcel.com/en
- Bundesnetzagentur Paketpreisvergleich 2025: https://www.bundesnetzagentur.de/SharedDocs/Mediathek/Berichte/2025/Paketpreisvergleich_2025.pdf
- BPEX KEP-Studie 2025: https://bpex-ev.de/presse/meldung/kep-studie-2025
- Parcel2Go (Wikipedia): https://en.wikipedia.org/wiki/Parcel2Go
- Parcel2Go MBO: https://businesscloud.co.uk/news/mbo-at-comparison-site-parcel2go/
- Parcelhero (Wikipedia): https://en.wikipedia.org/wiki/Parcelhero
- DHL × Vinted: https://www.dhl.com/de-de/microsites/core/zugestellt/globaler-handel/secondhand-trifft-packstation-dhl-und-vinted-bauen-partnerschaft-aus.html
- Vinted individueller Versand: https://www.vinted.com/help/443-wie-funktioniert-individueller-versand
- HOW2SHIP LLC: https://brokersnapshot.com/Company?dot=3024882&prefix=MC&docket=36372
- How2ship auf uShip: https://www.uship.com/profile/how2ship/
- Versandpreis (iOS): https://apps.apple.com/de/app/versandpreis/id972360669
- Versandpreis (Google Play): https://play.google.com/store/apps/details?id=com.mypaketkasten.vergleichsapp
- Versandpreis-App (Mypaketkasten): https://mypaketkasten.de/versandkostenrechner-app
- PortoCheck (iOS): https://apps.apple.com/us/app/portocheck/id323489326
- Eurosender App-Launch: https://blog.eurosender.com/eurosender-app-launch/
- Eurosender Mobile (Google Play): https://play.google.com/store/apps/details?id=com.eurosender.app
- Hermes AR-Paketgröße: https://newsroom.hermesworld.com/augmented-reality-hermes-app-erkennt-paketgroesse-per-smartphone-kamera-14417/
- DHL Packset AR: https://www.appgefahren.de/dhl-packset-mit-der-kamera-die-richtige-paketgroesse-bestimmen-209228.html
- Paketdienst-Apps im Test (connect): https://www.connect-living.de/vergleich/paketdienst-apps-vergleichstest-3202182.html
- Parcello (iOS): https://apps.apple.com/de/app/parcello-sendungsverfolgung/id1061039420
- Parcel2Go App (Google Play): https://play.google.com/store/apps/details?id=com.parcel2go.parcel2goapp
- Parcel2Go Trustpilot: https://www.trustpilot.com/review/www.parcel2go.com
- Pirate Ship / Shippo / Easyship Vergleich: https://www.aftership.com/blog/easyship-vs-pirate-ship-vs-shippo
- Eurosender Partnerprogramm (7 %): https://www.affiliate-marketing.de/partnerprogramme/eurosender.com
- Paketshop-Vergütung (paketda): https://www.paketda.de/news-kurznachrichten-20191213.html
