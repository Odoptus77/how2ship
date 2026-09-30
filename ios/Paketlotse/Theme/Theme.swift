import SwiftUI
import UIKit
import PaketlotseCore

/// Designsprache nach Referenz-UI: heller Blaugrau-Hintergrund, weiße Karten mit weichem Schatten,
/// Petrol als Primärfarbe („Lotse“), Orange als Akzent, runde Pill-Chips, SF Rounded.
enum Theme {
    static let background = Color(light: 0xE9F2F6, dark: 0x0F1B20)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1A2A31)
    static let primary = Color(light: 0x1F6E8C, dark: 0x4FA3C2)
    static let primaryDark = Color(light: 0x17566D, dark: 0x2E7C98)
    static let accent = Color(light: 0xF2A93B, dark: 0xF5B95A)
    static let accentSoft = Color(light: 0xFDF3DF, dark: 0x3A3020)
    static let chip = Color(light: 0xEEF3F5, dark: 0x24363E)
    static let textPrimary = Color(light: 0x1E2A32, dark: 0xEAF1F4)
    static let textSecondary = Color(light: 0x8A99A3, dark: 0x9FB0B9)

    static let cornerRadius: CGFloat = 24
    static let padding: CGFloat = 20
}

extension Font {
    static func lotse(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Carrier {
    /// Neutrale Kennfarbe je Paketdienst (keine Logos – Markenrichtlinien beachten).
    var tint: Color {
        switch self {
        case .dhl, .deutschePost: Color(light: 0xF4C21B, dark: 0xF4C21B)
        case .hermes: Color(light: 0x1A8FD0, dark: 0x3AA5E0)
        case .dpd: Color(light: 0xD8264A, dark: 0xE94A69)
        case .gls: Color(light: 0x23408E, dark: 0x5577C8)
        case .ups: Color(light: 0x6B4A2B, dark: 0x9C7650)
        }
    }

    var shortLabel: String {
        switch self {
        case .deutschePost: "Post"
        case .hermes: "H"
        default: displayName
        }
    }
}

enum Money {
    private static let locale = Locale(identifier: "de_DE")

    static func format(cents: Int) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: "EUR").locale(locale))
    }
}
