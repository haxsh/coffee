import Foundation

/// What the user brews with. Asked once in onboarding, frozen onto every brew
/// (they may change their water later, and history must not be rewritten).
///
/// Deliberately small: five options, one tap, no calculator. The water *question*
/// is in scope; a water *feature* — mineral profiles, TDS input, recipes for
/// building water — is not.
public enum WaterSource: String, Codable, Hashable, Sendable, CaseIterable {
    case ro
    case tap
    case bottled
    case roTapMix
    case unknown

    public var label: String {
        switch self {
        case .ro: return "RO / purifier"
        case .tap: return "Tap"
        case .bottled: return "Bottled"
        case .roTapMix: return "RO mixed with tap"
        case .unknown: return "Not sure"
        }
    }

    /// Straight RO is close to distilled — there are almost no minerals in it to
    /// bind flavour compounds, so extraction stalls no matter what the grinder is
    /// doing. This is the only case the engine treats as a cause.
    public var mayStallExtraction: Bool { self == .ro }
}

/// How much control the user actually has over grind — and therefore whether
/// "grind finer" is advice or noise.
///
/// This is the single most consequential thing the engine needs to know about a
/// user. Grind is the primary lever in every rule table, and a large share of the
/// target market buys pre-ground. Modelling it as a *capability* rather than
/// assuming it means the engine can give a pre-ground user real advice from the
/// levers they do have, instead of repeating one they can't act on.
public enum GrindControl: Hashable, Sendable {
    /// A grinder with a calibrated anchor: advice can be given in real units,
    /// "18 → 16 clicks on your Encore".
    case calibrated(Grinder, setting: Double)
    /// Owns a grinder but hasn't set it up: relative advice only,
    /// "one step finer than last time".
    case uncalibrated
    /// Buys pre-ground. **Grind is not a lever.** Advice must come from
    /// temperature, contact time, ratio, dose — or from suggesting a method that
    /// suits the grind they already have.
    case preGround

    public var isAdjustable: Bool {
        switch self {
        case .calibrated, .uncalibrated: return true
        case .preGround: return false
        }
    }

    public var grinder: Grinder? {
        if case let .calibrated(grinder, _) = self { return grinder }
        return nil
    }

    public var setting: Double? {
        if case let .calibrated(_, setting) = self { return setting }
        return nil
    }
}
