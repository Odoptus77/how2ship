import SwiftUI
import PaketlotseCore

// MARK: - Karten

struct CardModifier: ViewModifier {
    var background: Color = Theme.surface

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func card(background: Color = Theme.surface) -> some View {
        modifier(CardModifier(background: background))
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.lotse(compact ? 14 : 16, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 16)
            .background(Theme.primary.opacity(isEnabled ? 1 : 0.4), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Theme.primary)
            .frame(width: 52, height: 52)
            .background(Theme.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Chips

/// Auswahl-Chip (z. B. Schnellauswahl). Ausgewählt: Petrol, sonst Grau.
struct Chip: View {
    let title: String
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.lotse(14, .semibold))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.primary : Theme.surface, in: Capsule())
                .shadow(color: .black.opacity(isSelected ? 0.15 : 0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Umschaltbarer Chip mit Symbol für Zusatzleistungen (Versicherung, Abholung …).
struct ServiceChip: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.lotse(14, .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isOn ? .white : Theme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(isOn ? Theme.primary : Theme.surface, in: Capsule())
            .shadow(color: .black.opacity(isOn ? 0.15 : 0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Kleiner Info-Tag in Karten (z. B. „Online“, „Haftung 500 €“).
struct Tag: View {
    let text: String
    var systemImage: String?
    var tint: Color = Theme.textSecondary
    var background: Color = Theme.chip

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.lotse(11, .semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background, in: Capsule())
    }
}

// MARK: - Weitere Bausteine

struct CarrierAvatar: View {
    let carrier: Carrier
    var size: CGFloat = 46

    var body: some View {
        Text(carrier.shortLabel)
            .font(.lotse(carrier.shortLabel.count > 2 ? size * 0.26 : size * 0.42, .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(carrier.tint, in: Circle())
            .accessibilityLabel(carrier.displayName)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.lotse(18, .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.lotse(13, .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

/// Großes Petrol-Banner wie „Find jobs that suit you easily“ in der Referenz.
struct HeroCard: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemImage)
                .font(.system(size: 110, weight: .regular))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 18, y: -6)

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.lotse(22, .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.lotse(14))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.lotse(13, .heavy))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Theme.primaryDark, in: Capsule())
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Theme.primary, Theme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: Theme.primary.opacity(0.3), radius: 18, y: 10)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.primary.opacity(0.6))
            Text(title)
                .font(.lotse(17, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.lotse(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}

struct SampleDataBanner: View {
    var body: some View {
        Label("Beispielpreise – noch nicht mit den offiziellen Preislisten abgeglichen.", systemImage: "info.circle")
            .font(.lotse(12, .semibold))
            .foregroundStyle(Theme.primaryDark)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    /// Eingabefeld-Optik: grau hinterlegt, abgerundet, 52 pt hoch.
    func lotseField() -> some View {
        font(.lotse(16, .medium))
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Theme.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
