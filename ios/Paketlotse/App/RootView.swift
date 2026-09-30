import SwiftUI

struct RootView: View {
    enum Tab: Hashable {
        case ship, shipments, map, profile
    }

    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .ship

    var body: some View {
        @Bindable var store = store

        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Versenden", systemImage: "shippingbox") }
                .tag(Tab.ship)

            ShipmentsView()
                .tabItem { Label("Sendungen", systemImage: "list.bullet.rectangle.portrait") }
                .badge(store.openBookings.count)
                .tag(Tab.shipments)

            MapTabView()
                .tabItem { Label("Karte", systemImage: "map") }
                .tag(Tab.map)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(Theme.primary)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.sceneDidBecomeActive() }
        }
        .sheet(item: $store.promptBooking, onDismiss: { store.promptDismissed() }) { booking in
            TrackingPromptSheet(booking: booking)
        }
    }
}
