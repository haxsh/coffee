import Foundation

/// Exactly one change. Never a ranked list — with options, every user picks the
/// easiest one, two variables move at once, and the result is uninterpretable.
public struct Adjustment: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case grindFiner, grindCoarser, lessWater, moreWater, hotterWater, none

        public var isGrindChange: Bool { self == .grindFiner || self == .grindCoarser }
    }

    public let kind: Kind
    /// Imperative, two or three words. "Grind finer."
    public let headline: String
    /// The same instruction in the user's own units. "18 → 16 clicks on your Encore."
    public let detail: String
    /// The parameter to pre-fill on the next brew, if any.
    public let paramKey: BrewParamKey?
    public let newValue: Double?
    /// The grinder setting to pre-fill, in the user's units.
    public let newGrinderSetting: Double?

    public init(
        kind: Kind,
        headline: String,
        detail: String,
        paramKey: BrewParamKey? = nil,
        newValue: Double? = nil,
        newGrinderSetting: Double? = nil
    ) {
        self.kind = kind
        self.headline = headline
        self.detail = detail
        self.paramKey = paramKey
        self.newValue = newValue
        self.newGrinderSetting = newGrinderSetting
    }

    public var isActionable: Bool { kind != .none }

    /// Past-tense phrase for the loop-outcome message: "…after grinding finer".
    public var pastTensePhrase: String {
        switch kind {
        case .grindFiner: return "grinding finer"
        case .grindCoarser: return "grinding coarser"
        case .lessWater: return "using less water"
        case .moreWater: return "using more water"
        case .hotterWater: return "brewing hotter"
        case .none: return "changing nothing"
        }
    }

    public static let none = Adjustment(
        kind: .none,
        headline: "Change nothing",
        detail: "Brew it exactly the same way."
    )
}

public struct Diagnosis: Codable, Hashable, Sendable {
    /// Which rule fired. Kept so the table stays auditable — when a user says the
    /// advice was wrong, we can point at the exact rule and fix it.
    public let ruleID: Int
    /// Plain language, no jargon. "Under-extracted — it came out sour and a bit thin."
    public let verdict: String
    public let adjustment: Adjustment
    /// Two sentences, ending in the linked concept.
    public let explanation: String
    public let conceptID: String?

    public init(
        ruleID: Int,
        verdict: String,
        adjustment: Adjustment,
        explanation: String,
        conceptID: String? = nil
    ) {
        self.ruleID = ruleID
        self.verdict = verdict
        self.adjustment = adjustment
        self.explanation = explanation
        self.conceptID = conceptID
    }
}
