import SwiftUI
import UIKit
import CoffeeKit

/// The widget extension is a separate process and can't reach the app target's
/// `Theme`, so the palette is restated here. Kept to the handful of tokens the
/// widgets actually use rather than duplicating the whole design system.
///
/// Same meaning as in the app: **water** is the primary accent and marks
/// under-extraction, **heat** marks over-extraction.
enum WidgetTheme {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static let water = dynamic(light: 0x0E6E6B, dark: 0x54CFC8)
    static let heat = dynamic(light: 0xA8541F, dark: 0xE39058)
    static let target = dynamic(light: 0x1F6B3E, dark: 0x6FCB95)
    static let ink = dynamic(light: 0x121A19, dark: 0xE7EEEC)
    static let muted = dynamic(light: 0x5C6B69, dark: 0x94A5A2)
    static let paper = dynamic(light: 0xEFF2F1, dark: 0x0D1413)

    static func freshness(_ freshness: Freshness?) -> Color {
        switch freshness {
        case .peak: return target
        case .resting: return water
        case .fading: return heat
        case .stale, nil: return muted
        }
    }
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
