import SwiftUI
import MapKit
import PaketlotseCore

/// Karte mit echten Abgabestellen (F8): DHL Location Finder + OpenStreetMap.
struct MapTabView: View {
    @State private var locationManager = UserLocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .region(MapTabView.germany))
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchedCenter: CLLocationCoordinate2D?
    @State private var locations: [PickupLocation] = []
    @State private var selectedID: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var carrierFilter: Carrier?
    @State private var onlyLockers = false
    @State private var onlyOpenNow = false

    private static let service = LocationService()
    private var service: LocationService { Self.service }

    private static let germany = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
    )
    private static let filterCarriers: [Carrier] = [.dhl, .hermes, .dpd, .gls, .ups]

    private var filtered: [PickupLocation] {
        let now = Date()
        return locations.filter { location in
            if let carrierFilter, !location.carriers.contains(carrierFilter) { return false }
            if onlyLockers && !location.kind.isLocker { return false }
            if onlyOpenNow && location.isOpen(at: now) != true { return false }
            return true
        }
    }

    private var selected: PickupLocation? {
        locations.first { $0.id == selectedID }
    }

    /// „Hier suchen“ anbieten, wenn die Karte deutlich vom letzten Suchbereich wegbewegt wurde.
    private var showSearchHere: Bool {
        guard let region = visibleRegion, region.span.latitudeDelta < 0.2 else { return false }
        guard let searched = searchedCenter else { return true }
        return Self.distance(region.center, searched) > 800
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedID) {
                UserAnnotation()
                ForEach(filtered) { location in
                    Annotation(location.name, coordinate: location.coordinate, anchor: .bottom) {
                        LocationPin(location: location, isSelected: selectedID == location.id)
                    }
                    .tag(location.id)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }

            VStack(spacing: 10) {
                filterBar
                if showSearchHere && !isLoading {
                    Button {
                        if let region = visibleRegion { search(around: region.center, span: region.span) }
                    } label: {
                        Label("In diesem Bereich suchen", systemImage: "arrow.clockwise")
                            .font(.lotse(14, .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Theme.surface, in: Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    }
                    .foregroundStyle(Theme.primary)
                }
                if isLoading {
                    ProgressView("Suche Abgabestellen …")
                        .font(.lotse(13, .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.surface, in: Capsule())
                }
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, Theme.padding)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .task { locationManager.requestLocation() }
        .onChange(of: locationManager.lastLocation) { _, location in
            // Erste Standortbestimmung → automatisch in der Nähe suchen.
            guard let location, locations.isEmpty, searchedCenter == nil else { return }
            search(around: location.coordinate, span: nil)
        }
    }

    // MARK: - Filter

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Alle", isSelected: carrierFilter == nil) { carrierFilter = nil }
                ForEach(Self.filterCarriers) { carrier in
                    Chip(title: carrier.displayName, isSelected: carrierFilter == carrier) {
                        carrierFilter = carrierFilter == carrier ? nil : carrier
                    }
                }
                Chip(title: "Automaten", isSelected: onlyLockers) { onlyLockers.toggle() }
                Chip(title: "Jetzt geöffnet", isSelected: onlyOpenNow) { onlyOpenNow.toggle() }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Unten

    @ViewBuilder
    private var bottomPanel: some View {
        if let selected {
            LocationCard(location: selected, userLocation: locationManager.lastLocation) {
                selectedID = nil
            }
        } else if let errorMessage {
            infoCard(title: "Keine Verbindung", message: errorMessage)
        } else if locationManager.isDenied && locations.isEmpty {
            infoCard(
                title: "Standort nicht freigegeben",
                message: "Verschiebe die Karte zu deinem Ort und tippe auf „In diesem Bereich suchen“ – oder erlaube den Standort in den Einstellungen."
            )
        } else if !locations.isEmpty {
            HStack {
                Text("\(filtered.count) Abgabestellen")
                    .font(.lotse(14, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                attribution
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }

    private var attribution: some View {
        Link(destination: URL(string: "https://www.openstreetmap.org/copyright")!) {
            Text(service.usesDHLAPI ? "Daten: DHL · © OpenStreetMap" : "© OpenStreetMap-Mitwirkende")
                .font(.lotse(10))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func infoCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.lotse(16, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.lotse(13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Suche

    @MainActor
    private func search(around center: CLLocationCoordinate2D, span: MKCoordinateSpan?) {
        // Radius passend zum sichtbaren Bereich, 1–5 km.
        let visibleMeters = (span?.latitudeDelta ?? 0.02) * 111_000 / 2
        let radius = Int(min(max(visibleMeters, 1000), 5000))

        searchedCenter = center
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.locations(latitude: center.latitude, longitude: center.longitude, radiusMeters: radius)
                locations = result
                if let selectedID, !result.contains(where: { $0.id == selectedID }) { self.selectedID = nil }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}

extension PickupLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var symbolName: String {
        switch kind {
        case .packstation, .locker: "square.grid.3x3.square"
        case .filiale: "envelope.fill"
        case .paketshop: "shippingbox.fill"
        }
    }
}

// MARK: - Pin

private struct LocationPin: View {
    let location: PickupLocation
    let isSelected: Bool

    private var tint: Color {
        location.carriers.count == 1 ? location.carriers[0].tint : Theme.primary
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: location.symbolName)
                .font(.system(size: isSelected ? 17 : 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                .background(tint, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(tint)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Detailkarte

private struct LocationCard: View {
    let location: PickupLocation
    let userLocation: CLLocation?
    let onClose: () -> Void

    private var distanceText: String? {
        guard let userLocation else { return nil }
        let meters = location.distanceMeters(toLatitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        return measurement.formatted(.measurement(width: .abbreviated, usage: .road).locale(Locale(identifier: "de_DE")))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: -8) {
                    ForEach(location.carriers.prefix(3), id: \.self) { carrier in
                        CarrierAvatar(carrier: carrier, size: 38)
                            .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(location.name)
                        .font(.lotse(17, .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    Text(location.addressLine.isEmpty ? location.kind.displayName : location.addressLine)
                        .font(.lotse(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Theme.chip, in: Circle())
                }
                .accessibilityLabel("Schließen")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Tag(text: location.kind.displayName, systemImage: location.symbolName, tint: Theme.primary)
                    openingTag
                    if let distanceText { Tag(text: distanceText, systemImage: "figure.walk") }
                }
            }

            if let today = location.openingHoursText(on: Date()) {
                Text("Heute: \(today)")
                    .font(.lotse(13))
                    .foregroundStyle(Theme.textSecondary)
            } else if let raw = location.openingHoursText {
                Text("Öffnungszeiten: \(raw)")
                    .font(.lotse(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            Button("Route anzeigen") { openInMaps() }
                .buttonStyle(PrimaryButtonStyle(compact: true))

            Text(location.source == .dhl ? "Quelle: DHL" : "Quelle: © OpenStreetMap-Mitwirkende")
                .font(.lotse(10))
                .foregroundStyle(Theme.textSecondary)
        }
        .card()
    }

    @ViewBuilder
    private var openingTag: some View {
        switch location.isOpen(at: Date()) {
        case .some(true):
            Tag(text: "Jetzt geöffnet", systemImage: "clock", tint: .green, background: Color.green.opacity(0.12))
        case .some(false):
            Tag(text: "Geschlossen", systemImage: "clock", tint: .red, background: Color.red.opacity(0.12))
        case .none:
            Tag(text: "Öffnungszeiten unbekannt", systemImage: "clock")
        }
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        item.name = location.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
