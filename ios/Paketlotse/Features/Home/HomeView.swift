import SwiftUI
import PaketlotseCore

struct QuickPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let parcel: ParcelDimensions

    static let all: [QuickPreset] = [
        QuickPreset(id: "schuhkarton", title: "Schuhkarton", parcel: .init(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.0)),
        QuickPreset(id: "buch", title: "Buch", parcel: .init(lengthCm: 25, widthCm: 18, heightCm: 4, weightKg: 0.6)),
        QuickPreset(id: "wein", title: "Weinflasche", parcel: .init(lengthCm: 38, widthCm: 12, heightCm: 12, weightKg: 1.6)),
        QuickPreset(id: "laptop", title: "Laptop", parcel: .init(lengthCm: 45, widthCm: 33, heightCm: 8, weightKg: 3.0)),
        QuickPreset(id: "umzug", title: "Umzugskarton", parcel: .init(lengthCm: 60, widthCm: 33, heightCm: 34, weightKg: 12.0)),
    ]
}

struct HomeView: View {
    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var selectedPreset: String?
    @State private var showResults = false
    @State private var showMeasure = false

    private var parcel: ParcelDimensions? {
        guard let l = Self.number(length), let w = Self.number(width),
              let h = Self.number(height), let kg = Self.number(weight) else { return nil }
        let parcel = ParcelDimensions(lengthCm: l, widthCm: w, heightCm: h, weightKg: kg)
        return parcel.isValid ? parcel : nil
    }

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

                    SectionHeader(title: "Maße & Gewicht")
                    measureCard

                    Button("Preise vergleichen") { showResults = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(parcel == nil)
                }
                .padding(Theme.padding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showResults) {
                if let parcel { ResultsView(parcel: parcel) }
            }
            .sheet(isPresented: $showMeasure) { MeasureComingSoonView() }
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
        selectedPreset = preset.id
    }

    private static func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
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

/// Platzhalter bis zur AR-Vermessung (ARKit/LiDAR) – nächster Entwicklungsschritt.
struct MeasureComingSoonView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundStyle(Theme.primary)
            Text("Kamera-Vermessung")
                .font(.lotse(22, .bold))
            Text("Stell deinen Karton auf eine ebene Fläche und tippe die Ecken an – Paketlotse misst Länge, Breite und Höhe. Die Bilder bleiben auf deinem Gerät.\n\nDiese Funktion ist in Arbeit.")
                .font(.lotse(15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Verstanden") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
