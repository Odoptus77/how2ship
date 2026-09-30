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
   - **Karton mit der Handykamera vermessen** (AR bzw. LiDAR). Das ist ein echtes App-Argument, das die Web-Rechner nicht haben.
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
