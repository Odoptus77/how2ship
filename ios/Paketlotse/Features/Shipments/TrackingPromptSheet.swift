import SwiftUI
import PaketlotseCore

/// Abfrage der Sendungsnummer (Konzept 4.2).
/// Mit `booking`: nach der Rückkehr von einer Buchung. Ohne: „+ Sendung hinzufügen“.
struct TrackingPromptSheet: View {
    let booking: PendingBooking?

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var name = ""
    @State private var carrier: Carrier
    @State private var showScanner = false

    init(booking: PendingBooking?) {
        self.booking = booking
        _carrier = State(initialValue: booking?.carrier ?? .dhl)
    }

    private var normalized: String { TrackingNumberDetector.normalize(number) }
    private var detected: [Carrier] { TrackingNumberDetector.candidates(for: number) }
    private var formatMismatch: Bool { normalized.count >= 8 && !detected.contains(carrier) }
    private var canSubmit: Bool { normalized.count >= 8 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                HStack(spacing: 10) {
                    TextField("Sendungsnummer", text: $number)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .monospaced()
                        .lotseField()
                    Button { showScanner = true } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .buttonStyle(IconButtonStyle())
                    .disabled(!BarcodeScannerView.isAvailable)
                    .accessibilityLabel("Barcode scannen")
                }

                // System-Button: kein Hinweis „Paketlotse hat eingefügt“, kein heimliches Auslesen.
                PasteButton(payloadType: String.self) { strings in
                    guard let text = strings.first else { return }
                    let found = TrackingNumberDetector.extract(from: text).first ?? TrackingNumberDetector.normalize(text)
                    Task { @MainActor in apply(found) }
                }
                .buttonBorderShape(.capsule)
                .tint(Theme.primary)

                if booking == nil || formatMismatch {
                    carrierPicker
                }
                if formatMismatch {
                    Label("Das sieht nicht nach einer \(carrier.displayName)-Nummer aus. Anderer Paketdienst?", systemImage: "exclamationmark.triangle.fill")
                        .font(.lotse(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }

                TextField("Name (optional), z. B. „Geschenk für Oma“", text: $name)
                    .lotseField()

                Button("Sendung verfolgen") {
                    store.captureTrackingNumber(number, carrier: carrier, name: name, booking: booking)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSubmit)

                if let booking {
                    HStack {
                        Button("Später erinnern") { dismiss() }
                        Spacer()
                        Button("Nicht gebucht") {
                            store.markNotBooked(booking)
                            dismiss()
                        }
                    }
                    .font(.lotse(14, .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 8)
                }
            }
            .padding(24)
        }
        .background(Theme.surface.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: number) {
            // Ohne Buchung: Paketdienst aus dem Nummernformat übernehmen.
            if booking == nil, let first = detected.first { carrier = first }
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { payload in
                let found = TrackingNumberDetector.extract(from: payload).first ?? TrackingNumberDetector.normalize(payload)
                apply(found)
                showScanner = false
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            if let booking {
                CarrierAvatar(carrier: booking.carrier)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Theme.primary, in: Circle())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.map { "\($0.carrier.displayName) \($0.product) – gebucht?" } ?? "Sendung hinzufügen")
                    .font(.lotse(19, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Füge die Sendungsnummer hinzu und wir sagen dir Bescheid, wo dein Paket ist.")
                    .font(.lotse(14))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var carrierPicker: some View {
        HStack {
            Text("Paketdienst")
                .font(.lotse(14, .semibold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Picker("Paketdienst", selection: $carrier) {
                ForEach(Carrier.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(Theme.primary)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Theme.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func apply(_ found: String) {
        number = found
        if booking == nil, let first = TrackingNumberDetector.candidates(for: found).first {
            carrier = first
        }
    }
}
