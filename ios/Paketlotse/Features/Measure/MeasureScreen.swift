import SwiftUI
import ARKit
import PaketlotseCore

/// Kamera-Vermessung in drei getrennten Schritten: Länge, Breite, Höhe – jeweils zwei Punkte.
/// Vor jedem Schritt erscheint eine 3D-Anleitung (abschaltbar, jederzeit über „?“ erreichbar).
struct MeasureScreen: View {
    /// Übergibt Länge, Breite, Höhe in cm (bereits inkl. Sicherheitsaufschlag aufgerundet).
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
    @State private var tutorialDimension: BoxMeasurement.Dimension?
    /// Anleitungen, die in dieser Messung schon automatisch gezeigt wurden (nicht erneut bei „Rückgängig“).
    @State private var shownTutorials: Set<BoxMeasurement.Dimension> = []
    @AppStorage(MeasureTutorialSheet.disabledKey) private var tutorialDisabled = false

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
                DimensionProgress(measurement: measurement)
                if let error = session.errorMessage {
                    errorCard(error)
                } else if let dimension = measurement.currentDimension {
                    instructionCard(dimension)
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
        .sheet(item: $tutorialDimension) { dimension in
            MeasureTutorialSheet(dimension: dimension) { tutorialDimension = nil }
        }
        .task {
            // Kurz warten, bis die Kamera eingeblendet ist, dann die erste Anleitung zeigen.
            try? await Task.sleep(for: .milliseconds(500))
            showTutorialIfNeeded()
        }
        .onChange(of: measurement.currentDimension) {
            showTutorialIfNeeded()
        }
    }

    /// Vor jedem Schritt (Länge, Breite, Höhe) einmal – außer „Nicht erneut anzeigen“ ist aktiv.
    private func showTutorialIfNeeded() {
        guard !tutorialDisabled,
              tutorialDimension == nil,
              let dimension = measurement.currentDimension,
              !measurement.isAwaitingSecondPoint,
              !shownTutorials.contains(dimension)
        else { return }
        shownTutorials.insert(dimension)
        tutorialDimension = dimension
    }

    private func restart() {
        session.reset()
        shownTutorials = []
        showTutorialIfNeeded()
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

            Text("Paket vermessen")
                .font(.lotse(16, .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()

            // Anleitung jederzeit öffnen – auch wenn sie abgeschaltet oder weggeklickt wurde.
            Button {
                tutorialDimension = measurement.currentDimension ?? .length
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Anleitung anzeigen")
        }
        .foregroundStyle(.white)
    }

    private func instructionCard(_ dimension: BoxMeasurement.Dimension) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schritt \(dimension.number) von 3 · \(dimension.title) · Punkt \(measurement.isAwaitingSecondPoint ? 2 : 1) von 2")
                .font(.lotse(12, .bold))
                .foregroundStyle(Theme.accent)
            Text(dimension.instruction(forSecondPoint: measurement.isAwaitingSecondPoint))
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
                    Button("Neu messen") { restart() }
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

/// Fortschritt der drei Strecken: erledigt (mit Wert), aktuell, offen.
private struct DimensionProgress: View {
    let measurement: BoxMeasurement

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BoxMeasurement.Dimension.allCases) { dimension in
                let value = measurement.valueCm(for: dimension)
                let isCurrent = measurement.currentDimension == dimension
                HStack(spacing: 5) {
                    Image(systemName: value != nil ? "checkmark.circle.fill" : (isCurrent ? "circle.dotted" : "circle"))
                    Text(value.map { "\(Int(BoxMeasurement.roundUp($0, marginCm: BoxMeasurement.defaultSafetyMarginCm))) cm" } ?? dimension.title)
                        .contentTransition(.numericText())
                }
                .font(.lotse(13, .bold))
                .foregroundStyle(value != nil || isCurrent ? .white : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    value != nil ? AnyShapeStyle(Theme.primary) : (isCurrent ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.ultraThinMaterial)),
                    in: Capsule()
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: measurement.points.count)
    }
}

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
