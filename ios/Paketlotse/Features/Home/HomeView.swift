import SwiftUI
import PaketlotseCore

struct QuickPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let parcel: ParcelDimensions
    /// Sinnvolle Zusatzleistungen für diesen Inhalt (z. B. Laptop: versichert + Sendungsverfolgung).
    var requirements: ShippingRequirements = .none

    static let all: [QuickPreset] = [
        QuickPreset(id: "schuhkarton", title: "Schuhkarton", parcel: .init(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.0)),
        QuickPreset(id: "buch", title: "Buch", parcel: .init(lengthCm: 25, widthCm: 18, heightCm: 4, weightKg: 0.6)),
        QuickPreset(id: "wein", title: "Weinflasche", parcel: .init(lengthCm: 38, widthCm: 12, heightCm: 12, weightKg: 1.6),
                    requirements: .init(requiresTracking: true)),
        QuickPreset(id: "laptop", title: "Laptop", parcel: .init(lengthCm: 45, widthCm: 33, heightCm: 8, weightKg: 3.0),
                    requirements: .init(declaredValueEuro: 1000, requiresTracking: true)),
        QuickPreset(id: "umzug", title: "Umzugskarton", parcel: .init(lengthCm: 60, widthCm: 33, heightCm: 34, weightKg: 12.0),
                    requirements: .init(requiresPickup: true)),
    ]
}

struct HomeView: View {
    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var selectedPreset: String?
    @State private var insure = false
    @State private var valueText = ""
    @State private var tracking = false
    @State private var pickup = false
    @State private var signature = false
    @State private var packstation = false
    @State private var showResults = false
    @State private var showMeasure = false

    private var parcel: ParcelDimensions? {
        guard let l = Self.number(length), let w = Self.number(width),
              let h = Self.number(height), let kg = Self.number(weight) else { return nil }
        let parcel = ParcelDimensions(lengthCm: l, widthCm: w, heightCm: h, weightKg: kg)
        return parcel.isValid ? parcel : nil
    }

    private var declaredValue: Int? {
        Int(valueText.filter(\.isNumber))
    }

    private var requirements: ShippingRequirements {
        ShippingRequirements(
            declaredValueEuro: insure ? declaredValue : nil,
            requiresTracking: tracking,
            requiresPickup: pickup,
            requiresSignature: signature,
            requiresPackstation: packstation
        )
    }

    /// Versicherung gewählt, aber noch kein Warenwert eingetragen.
    private var isMissingValue: Bool { insure && (declaredValue ?? 0) == 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    HeroCard(
                        title: "Miss dein Paket mit der Kamera",
                        subtitle: "Wir finden die passende Größe bei allen Paketdiensten.",
                        buttonTitle: "JETZT MESSEN",
                        systemImage: "cube.transparent"
                    ) { showMeasure = true }

                    SectionHeader(title: "Schnellauswahl")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(QuickPreset.all) { preset in
                                Chip(title: preset.title, isSelected: selectedPreset == preset.id) { apply(preset) }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                    }

                    SectionHeader(title: "Zusatzleistungen")
                    servicesSection

                    SectionHeader(title: "Maße & Gewicht")
                    measureCard

                    Button("Preise vergleichen") { showResults = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(parcel == nil || isMissingValue)
                }
                .padding(Theme.padding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showResults) {
                if let parcel { ResultsView(parcel: parcel, requirements: requirements) }
            }
            .fullScreenCover(isPresented: $showMeasure) {
                MeasureScreen { measuredLength, measuredWidth, measuredHeight in
                    length = Self.format(measuredLength)
                    width = Self.format(measuredWidth)
                    height = Self.format(measuredHeight)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Paketlotse")
                .font(.lotse(14, .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("Finde den besten Weg\nfür dein Paket 📦")
                .font(.lotse(28, .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.top, 8)
    }

    private var measureCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                MeasureField(title: "Länge", unit: "cm", text: $length)
                MeasureField(title: "Breite", unit: "cm", text: $width)
                MeasureField(title: "Höhe", unit: "cm", text: $height)
            }
            MeasureField(title: "Gewicht", unit: "kg", text: $weight)
        }
        .card()
        .onChange(of: [length, width, height, weight]) {
            if let preset = QuickPreset.all.first(where: { $0.id == selectedPreset }), parcel != preset.parcel {
                selectedPreset = nil
            }
        }
    }

    private func apply(_ preset: QuickPreset) {
        length = Self.format(preset.parcel.lengthCm)
        width = Self.format(preset.parcel.widthCm)
        height = Self.format(preset.parcel.heightCm)
        weight = Self.format(preset.parcel.weightKg)
        let services = preset.requirements
        insure = services.needsInsurance
        valueText = services.declaredValueEuro.map { String($0) } ?? ""
        tracking = services.requiresTracking
        pickup = services.requiresPickup
        signature = services.requiresSignature
        packstation = services.requiresPackstation
        selectedPreset = preset.id
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ServiceChip(title: "Versichern", systemImage: "shield", isOn: $insure)
                ServiceChip(title: "Sendungsverfolgung", systemImage: "location", isOn: $tracking)
                ServiceChip(title: "Abholung", systemImage: "house", isOn: $pickup)
                ServiceChip(title: "Unterschrift", systemImage: "signature", isOn: $signature)
                ServiceChip(title: "Packstation", systemImage: "square.grid.3x3.square", isOn: $packstation)
            }

            if insure {
                VStack(alignment: .leading, spacing: 10) {
                    MeasureField(title: "Warenwert", unit: "€", text: $valueText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([100, 500, 1000, 2500], id: \.self) { value in
                                Chip(title: Self.formatEuro(value) + " €", isSelected: declaredValue == value) {
                                    valueText = String(value)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                    }
                    Text(isMissingValue
                         ? "Bitte Warenwert eintragen."
                         : "Liegt der Wert über der Grundhaftung, rechnen wir die passende Versicherung in den Preis ein.")
                        .font(.lotse(12))
                        .foregroundStyle(isMissingValue ? Theme.accent : Theme.textSecondary)
                }
                .card()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: insure)
    }

    private static func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }

    private static func formatEuro(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: "de_DE")))
    }

    private static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "de_DE")))
    }
}

struct MeasureField: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.lotse(12, .semibold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 4) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.lotse(20, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.lotse(13, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
