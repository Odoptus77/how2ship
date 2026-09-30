import SwiftUI
import MapKit

/// Karte mit Paketshops und Packstationen (F8). Standortdaten folgen im nächsten Schritt.
struct MapTabView: View {
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
    )

    var body: some View {
        Map(position: $position)
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Paketshops & Packstationen")
                        .font(.lotse(17, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Hier findest du bald Abgabestellen in deiner Nähe – mit Öffnungszeiten und Filter „Jetzt geöffnet“.")
                        .font(.lotse(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                .padding(Theme.padding)
            }
    }
}
