import SwiftUI
import UIKit
import PaketlotseCore

struct ShipmentsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.openBookings.isEmpty && store.shipments.isEmpty {
                        EmptyStateView(
                            systemImage: "shippingbox",
                            title: "Noch keine Sendungen",
                            message: "Nach einer Buchung fragen wir dich nach der Sendungsnummer. Du kannst auch Pakete hinzufügen, die du erwartest."
                        )
                    }

                    if !store.openBookings.isEmpty {
                        SectionHeader(title: "Offene Buchungen")
                        ForEach(store.openBookings) { booking in
                            Button { store.openPrompt(forBookingID: booking.id) } label: {
                                OpenBookingRow(booking: booking)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !store.activeShipments.isEmpty {
                        SectionHeader(title: "Unterwegs")
                        ForEach(store.activeShipments) { shipment in
                            NavigationLink(value: shipment) { ShipmentRow(shipment: shipment) }
                                .buttonStyle(.plain)
                        }
                    }

                    if !store.deliveredShipments.isEmpty {
                        SectionHeader(title: "Zugestellt")
                        ForEach(store.deliveredShipments) { shipment in
                            NavigationLink(value: shipment) { ShipmentRow(shipment: shipment) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Theme.padding)
            }
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
    let shipment: Shipment

    @Environment(AppStore.self) private var store
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
                    if shipment.events.isEmpty {
                        Text("Die automatische Statusabfrage folgt mit dem Paketlotse-Server. Bis dahin kannst du den Status direkt beim Paketdienst ansehen.")
                            .font(.lotse(14))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(shipment.events.sorted { $0.date > $1.date }, id: \.self) { event in
                            TimelineRow(event: event)
                        }
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
