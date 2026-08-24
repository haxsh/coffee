import Foundation

/// Why this type exists: "grind one step finer" is meaningless advice without a
/// mapping to the dial in front of the user. Recipes carry a normalised
/// coarseness (0 = finest, 100 = coarsest); this translates it into *your* units.
public struct Grinder: Identifiable, Codable, Hashable, Sendable {
    public enum SettingType: String, Codable, Sendable {
        case clicks, numberedDial, stepless

        public func format(_ value: Double) -> String {
            switch self {
            case .clicks:
                return "\(Int(value.rounded())) clicks"
            case .numberedDial:
                return String(format: "%.0f", value)
            case .stepless:
                return String(format: "%.1f", value)
            }
        }
    }

    public let id: UUID
    public var brand: String
    public var model: String
    public var settingType: SettingType
    public var minSetting: Double
    public var maxSetting: Double
    /// The user's answer to the one calibration question we ask:
    /// "what setting do you use for pour-over?" That answer becomes normalised 50.
    /// Two taps, no measuring, no burr-gap micrometry.
    public var pourOverAnchor: Double
    /// How far to move the dial for one diagnosis-recommended step.
    /// Two clicks on a click grinder is roughly one perceptible step in the cup.
    public var adjustmentStep: Double

    public init(
        id: UUID = UUID(),
        brand: String,
        model: String,
        settingType: SettingType,
        minSetting: Double,
        maxSetting: Double,
        pourOverAnchor: Double,
        adjustmentStep: Double
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.settingType = settingType
        self.minSetting = minSetting
        self.maxSetting = maxSetting
        self.pourOverAnchor = pourOverAnchor
        self.adjustmentStep = adjustmentStep
    }

    public var displayName: String {
        brand.isEmpty ? model : "\(brand) \(model)"
    }

    public func clamp(_ setting: Double) -> Double {
        min(max(setting, minSetting), maxSetting)
    }

    /// Piecewise-linear map hinged on the user's anchor, so the setting they
    /// actually use lands exactly at the middle of the scale.
    public func normalised(fromSetting setting: Double) -> Double {
        let s = clamp(setting)
        if s <= pourOverAnchor {
            let span = pourOverAnchor - minSetting
            guard span > 0 else { return 50 }
            return 50 * (s - minSetting) / span
        } else {
            let span = maxSetting - pourOverAnchor
            guard span > 0 else { return 50 }
            return 50 + 50 * (s - pourOverAnchor) / span
        }
    }

    public func setting(fromNormalised normalised: Double) -> Double {
        let n = min(max(normalised, 0), 100)
        let raw: Double
        if n <= 50 {
            raw = minSetting + (pourOverAnchor - minSetting) * (n / 50)
        } else {
            raw = pourOverAnchor + (maxSetting - pourOverAnchor) * ((n - 50) / 50)
        }
        return clamp(rounded(raw))
    }

    /// Negative steps go finer, positive coarser.
    public func adjustedSetting(from setting: Double, steps: Int) -> Double {
        clamp(rounded(setting + adjustmentStep * Double(steps)))
    }

    public func format(_ setting: Double) -> String {
        settingType.format(setting)
    }

    private func rounded(_ value: Double) -> Double {
        switch settingType {
        case .clicks, .numberedDial: return value.rounded()
        case .stepless: return (value * 10).rounded() / 10
        }
    }

    /// A neutral stand-in for users who skip grinder setup or grind pre-ground.
    /// Guidance falls back to descriptive terms rather than meaningless numbers.
    public static let unknown = Grinder(
        brand: "",
        model: "My grinder",
        settingType: .numberedDial,
        minSetting: 0,
        maxSetting: 100,
        pourOverAnchor: 50,
        adjustmentStep: 5
    )

    public static let baratzaEncore = Grinder(
        brand: "Baratza",
        model: "Encore",
        settingType: .clicks,
        minSetting: 1,
        maxSetting: 40,
        pourOverAnchor: 18,
        adjustmentStep: 2
    )

    public static let comandanteC40 = Grinder(
        brand: "Comandante",
        model: "C40",
        settingType: .clicks,
        minSetting: 1,
        maxSetting: 50,
        pourOverAnchor: 24,
        adjustmentStep: 2
    )

    public static let onedFellowOde2 = Grinder(
        brand: "Fellow",
        model: "Ode Gen 2",
        settingType: .numberedDial,
        minSetting: 1,
        maxSetting: 11,
        pourOverAnchor: 5,
        adjustmentStep: 1
    )

    public static let knownGrinders: [Grinder] = [
        .baratzaEncore, .comandanteC40, .onedFellowOde2
    ]
}
