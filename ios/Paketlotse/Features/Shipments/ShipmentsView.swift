import SwiftUI
import UIKit
import PaketlotseCore

struct ShipmentsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var path: [Shipment] = []

    var body: some View {
        NavigationStack(path: $path) {
            // List statt ScrollView: nur so gibt es das native „Nach links wischen zum Löschen“.
            List {
                if store.openBookings.isEmpty && store.shipments.isEmpty {
                    EmptyStateView(
                        systemImage: "shippingbox",
                        title: "Noch keine Sendungen",
                        message: "Nach einer Buchung fragen wir dich nach der Sendungsnummer. Du kannst auch Pakete hinzufügen, die du erwartest."
                    )
                    .cardRow()
                }

                if !store.openBookings.isEmpty {
                    SectionHeader(title: "Offene Buchungen")
                        .cardRow(top: 12)
                    ForEach(store.openBookings) { booking in
                        Button { store.openPrompt(forBookingID: booking.id) } label: {
                            OpenBookingRow(booking: booking)
                        }
                        .buttonStyle(.plain)
                        .cardRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.deleteBooking(booking) }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }

                shipmentSection("Unterwegs", store.activeShipments)
                shipmentSection("Zugestellt", store.deliveredShipments)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await store.syncWithServer() }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Sendungen")
            .navigationDestination(for: Shipment.self) { ShipmentDetailView(shipment: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Sendung hinzufügen")
                }
            }
            .sheet(isPresented: $showAdd) { TrackingPromptSheet(booking: nil) }
        }
    }

    @ViewBuilder
    private func shipmentSection(_ title: String, _ shipments: [Shipment]) -> some View {
        if !shipments.isEmpty {
            SectionHeader(title: title)
                .cardRow(top: 12)
            ForEach(shipments) { shipment in
                Button { path.append(shipment) } label: {
                    ShipmentRow(shipment: shipment)
                }
                .buttonStyle(.plain)
                .cardRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { store.delete(shipment) }
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private extension View {
    /// Listenzeile im Karten-Look: ohne Trennlinie und Hintergrund, mit Seitenabstand wie im Rest der App.
    func cardRow(top: CGFloat = 6) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: Theme.padding, bottom: 6, trailing: Theme.padding))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct OpenBookingRow: View {
    let booking: PendingBooking

    var body: some View {
        HStack(spacing: 14) {
            CarrierAvatar(carrier: booking.carrier, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(booking.carrier.displayName) \(booking.product)")
                    .font(.lotse(16, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Gebucht? Sendungsnummer hinzufügen")
                    .font(.lotse(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.accent)
        }
        .card(background: Theme.accentSoft)
    }
}

struct ShipmentRow: View {
    let shipment: Shipment

    var body: some View {
        HStack(spacing: 14) {
            CarrierAvatar(carrier: shipment.carrier, size: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text(shipment.displayName)
                    .font(.lotse(16, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(shipment.number)
                    .font(.lotse(12).monospaced())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            StatusTag(status: shipment.status)
        }
        .card()
    }
}

struct StatusTag: View {
    let status: ShipmentStatus

    private var color: Color {
        switch status {
        case .registered: Theme.textSecondary
        case .inTransit: Theme.primary
        case .outForDelivery: Theme.accent
        case .delivered: .green
        case .problem: .red
        }
    }

    var body: some View {
        Tag(text: status.displayName, tint: color, background: color.opacity(0.12))
    }
}

struct ShipmentDetailView: View {
    private let initial: Shipment

    @Environment(AppStore.self) private var store

    init(shipment: Shipment) {
        initial = shipment
    }

    /// Immer den aktuellen Stand aus dem Store zeigen (Updates vom Server).
    private var shipment: Shipment {
        store.shipments.first { $0.id == initial.id } ?? initial
    }
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    CarrierAvatar(carrier: shipment.carrier, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shipment.displayName)
                            .font(.lotse(20, .bold))
                        HStack(spacing: 6) {
                            Text(shipment.number)
                                .font(.lotse(13).monospaced())
                                .foregroundStyle(Theme.textSecondary)
                                .textSelection(.enabled)
                            Button {
                                UIPasteboard.general.string = shipment.number
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.primary)
                            .accessibilityLabel("Sendungsnummer kopieren")
                        }
                    }
                    Spacer()
                }
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Status")
                            .font(.lotse(16, .bold))
                        Spacer()
                        StatusTag(status: shipment.status)
                    }
                    if let expected = shipment.expectedDelivery, shipment.status != .delivered {
                        Label("Voraussichtlich \(expected.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                            .font(.lotse(14, .semibold))
                            .foregroundStyle(Theme.primary)
                    }
                    if shipment.events.isEmpty {
                        Text(store.api.isConfigured
                             ? "Noch keine Meldungen vom Paketdienst. Viele Sendungen erscheinen erst nach der Einlieferung – wir sagen dir Bescheid."
                             : "Automatische Statusabfrage ist nicht eingerichtet. Du kannst den Status direkt beim Paketdienst ansehen.")
                            .font(.lotse(14))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(shipment.events.sorted { $0.date > $1.date }, id: \.self) { event in
                            TimelineRow(event: event)
                        }
                    }
                    if let updated = shipment.lastUpdated {
                        Text("Letzte Änderung: \(updated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.lotse(11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .card()

                if let url = shipment.carrier.trackingURL(for: shipment.number) {
                    Button("Beim Paketdienst öffnen") { openURL(url) }
                        .buttonStyle(PrimaryButtonStyle())
                }

                Button("Sendung löschen", role: .destructive) {
                    store.delete(shipment)
                    dismiss()
                }
                .font(.lotse(14, .semibold))
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.padding)
        }
        .refreshable { await store.refresh(shipment) }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Sendung")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimelineRow: View {
    let event: TrackingEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Theme.primary)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.text)
                    .font(.lotse(14, .semibold))
                Text([event.date.formatted(date: .abbreviated, time: .shortened), event.location].compactMap { $0 }.joined(separator: " · "))
                    .font(.lotse(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
