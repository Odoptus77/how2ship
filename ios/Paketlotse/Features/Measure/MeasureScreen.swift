import SwiftUI
import ARKit
import PaketlotseCore

/// Kamera-Vermessung: 3 Bodenecken + Deckel → Länge, Breite, Höhe (inkl. 1 cm Sicherheitsaufschlag).
struct MeasureScreen: View {
    /// Übergibt Länge, Breite, Höhe in cm (bereits aufgerundet).
    let onApply: (Double, Double, Double) -> Void

    var body: some View {
        if ARWorldTrackingConfiguration.isSupported {
            MeasureARContent(onApply: onApply)
        } else {
            MeasureUnsupportedView()
        }
    }
}

private struct MeasureARContent: View {
    let onApply: (Double, Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var session = MeasureSession()
    @State private var showHelp = false
    @AppStorage("hasSeenMeasureHelp") private var hasSeenHelp = false

    private var measurement: BoxMeasurement { session.measurement }

    var body: some View {
        ZStack {
            ARMeasureView(model: session, points: measurement.points)
                .ignoresSafeArea()

            if !measurement.isComplete {
                Reticle(isActive: session.currentHit != nil)
            }

            VStack(spacing: 12) {
                topBar
                if let error = session.errorMessage {
                    errorCard(error)
                } else if let step = measurement.currentStep {
                    instructionCard(step)
                }
                Spacer()
                if let preview = session.previewCm, !measurement.isComplete {
                    liveValue(preview)
                }
                if measurement.isComplete {
                    resultCard
                } else {
                    controls
                }
            }
            .padding(Theme.padding)
        }
        .statusBarHidden()
        .sheet(isPresented: $showHelp) { MeasureHelpView() }
        .task {
            // Anleitung beim ersten Mal automatisch zeigen (nach dem Einblenden der Kamera).
            guard !hasSeenHelp else { return }
            try? await Task.sleep(for: .milliseconds(500))
            showHelp = true
            hasSeenHelp = true
        }
    }

    // MARK: Oben

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Schließen")

            Spacer()

            StepIndicator(completed: measurement.points.count, total: BoxMeasurement.Step.allCases.count)

            Spacer()

            Button { showHelp = true } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Anleitung")
        }
        .foregroundStyle(.white)
    }

    private func instructionCard(_ step: BoxMeasurement.Step) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schritt \(step.number) von 4 · \(step.title)")
                .font(.lotse(12, .bold))
                .foregroundStyle(Theme.accent)
            Text(step.instruction)
                .font(.lotse(15, .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let hint = session.trackingHint {
                Label(hint, systemImage: "iphone.gen3.radiowaves.left.and.right")
                    .font(.lotse(12))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
                .font(.lotse(15, .semibold))
                .foregroundStyle(.white)
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(PrimaryButtonStyle(compact: true))
        }
        .padding(16)
        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Unten

    private func liveValue(_ cm: Double) -> some View {
        Text("\(cm.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "de_DE")))) cm")
            .font(.lotse(28, .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: Capsule())
            .contentTransition(.numericText())
    }

    private var controls: some View {
        HStack(alignment: .center) {
            Button { session.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(measurement.points.isEmpty)
            .opacity(measurement.points.isEmpty ? 0.4 : 1)
            .accessibilityLabel("Letzten Punkt entfernen")

            Spacer()

            Button { session.addPoint() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(session.canAddPoint ? Theme.primary : Color.gray.opacity(0.6), in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            }
            .disabled(!session.canAddPoint)
            .accessibilityLabel("Punkt setzen")

            Spacer()

            // Platzhalter für Symmetrie
            Color.clear.frame(width: 56, height: 56)
        }
        .foregroundStyle(.white)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dein Paket")
                .font(.lotse(13, .bold))
                .foregroundStyle(Theme.textSecondary)

            if let dims = measurement.roundedDimensionsCm() {
                HStack(spacing: 10) {
                    ResultValue(title: "Länge", value: dims.length)
                    ResultValue(title: "Breite", value: dims.width)
                    ResultValue(title: "Höhe", value: dims.height)
                }

                Text("Inkl. 1 cm Sicherheitsaufschlag. Liegt ein Wert knapp an einer Grenze, lieber kurz nachmessen.")
                    .font(.lotse(12))
                    .foregroundStyle(Theme.textSecondary)

                if !measurement.isPlausible {
                    Label("Ein Wert wirkt ungewöhnlich – vermutlich wurde eine Ecke verfehlt. Bitte neu messen.", systemImage: "exclamationmark.triangle.fill")
                        .font(.lotse(12, .semibold))
                        .foregroundStyle(Theme.accent)
                }

                HStack(spacing: 10) {
                    Button("Neu messen") { session.reset() }
                        .font(.lotse(15, .bold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.chip, in: Capsule())

                    Button("Übernehmen") {
                        onApply(dims.length, dims.width, dims.height)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .card()
    }
}

// MARK: - Bausteine

private struct Reticle: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isActive ? Color.white : Color.white.opacity(0.4), lineWidth: 3)
                .frame(width: 44, height: 44)
            Circle()
                .fill(isActive ? Theme.accent : Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black.opacity(0.4), radius: 4)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .allowsHitTesting(false)
    }
}

private struct StepIndicator: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < completed ? Theme.accent : Color.white.opacity(0.4))
                    .frame(width: index == completed ? 22 : 10, height: 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: completed)
    }
}

private struct ResultValue: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.lotse(12, .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text("\(Int(value)) cm")
                .font(.lotse(22, .heavy))
                .foregroundStyle(Theme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MeasureHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("So misst du richtig")
                .font(.lotse(22, .bold))
            VStack(alignment: .leading, spacing: 10) {
                helpRow("1", "Stell den Karton auf den Boden oder einen Tisch mit etwas Platz drumherum.")
                helpRow("2", "Bewege das iPhone kurz langsam hin und her, bis der Kreis aufleuchtet.")
                helpRow("3", "Setze drei untere Ecken nacheinander – erst die lange, dann die kurze Seite.")
                helpRow("4", "Ziele zum Schluss auf den Deckel für die Höhe.")
            }
            Text("Die Kamerabilder werden nur auf deinem Gerät verarbeitet und nicht hochgeladen.")
                .font(.lotse(12))
                .foregroundStyle(Theme.textSecondary)
            Button("Los geht's") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }

    private func helpRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.lotse(14, .heavy))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.primary, in: Circle())
            Text(text)
                .font(.lotse(15))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Simulator oder Gerät ohne ARKit-Unterstützung.
private struct MeasureUnsupportedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 64))
                .foregroundStyle(Theme.primary)
            Text("Kamera-Vermessung nicht verfügbar")
                .font(.lotse(22, .bold))
                .multilineTextAlignment(.center)
            Text("Die Vermessung braucht ein iPhone mit ARKit-Unterstützung und funktioniert nicht im Simulator. Du kannst die Maße einfach von Hand eingeben.")
                .font(.lotse(15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button("Schließen") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}
