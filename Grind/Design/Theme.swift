import SwiftUI
import UIKit
import CoffeeKit

/// The palette is built around the subject's real world — measurement, water and
/// heat — rather than the beverage. Coffee apps default to cream and terracotta;
/// this one is an instrument.
///
/// The two accents also carry meaning rather than decoration: **water** marks
/// under-extraction and everything cool, **heat** marks over-extraction and
/// everything that ran too far. That mapping is used consistently on the taste
/// axes, the diagnosis screens and the journal, so the colour itself teaches the
/// extraction scale.
enum Theme {

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Cool teal. Water, under-extraction, and the app's primary accent.
    static let water = dynamic(light: 0x0E6E6B, dark: 0x54CFC8)
    /// Amber-rust. Heat, over-extraction, and warnings. Used sparingly.
    static let heat = dynamic(light: 0xA8541F, dark: 0xE39058)
    /// Reserved for the balanced cup and the "that worked" moment.
    static let target = dynamic(light: 0x1F6B3E, dark: 0x6FCB95)

    static let ink = dynamic(light: 0x121A19, dark: 0xE7EEEC)
    static let muted = dynamic(light: 0x5C6B69, dark: 0x94A5A2)
    static let faint = dynamic(light: 0x8A9A97, dark: 0x6E807D)
    static let paper = dynamic(light: 0xEFF2F1, dark: 0x0D1413)
    static let surface = dynamic(light: 0xFBFCFC, dark: 0x151D1C)
    static let surfaceAlt = dynamic(light: 0xE4EAE8, dark: 0x1B2625)
    static let line = dynamic(light: 0xD2DBD9, dark: 0x26332F)

    static func extractionColor(_ value: Int) -> Color {
        if value <= -1 { return water }
        if value >= 1 { return heat }
        return target
    }

    static func freshnessColor(_ freshness: Freshness?) -> Color {
        switch freshness {
        case .peak: return target
        case .resting: return water
        case .fading: return heat
        case .stale: return muted
        case nil: return muted
        }
    }

    /// The brew timer's clock. Tabular so the digits don't jitter as they change,
    /// and big enough to read from a metre away with wet hands.
    static func clock(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded).monospacedDigit()
    }

    static let label = Font.system(.caption, design: .monospaced).weight(.medium)
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension View {
    /// Uppercase mono label used for section headers and data captions.
    func sectionLabel() -> some View {
        self.font(Theme.label)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Theme.muted)
    }

    func cardBackground() -> some View {
        self.background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.line, lineWidth: 1)
            )
    }
}
