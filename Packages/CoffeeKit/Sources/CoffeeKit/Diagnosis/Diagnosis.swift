import Foundation

/// Exactly one change. Never a ranked list — with options, every user picks the
/// easiest one, two variables move at once, and the result is uninterpretable.
public struct Adjustment: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case grindFiner, grindCoarser
        case lessWater, moreWater
        case hotterWater, coolerWater
        case steepLonger, steepShorter
        case blendWater
        /// The honest answer when the user has no grinder and the grind they bought
        /// simply doesn't suit this brewer: change the brewer, not the technique.
        case tryDifferentMethod
        case none

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
    /// For `.tryDifferentMethod` — the method being suggested, so the UI can route
    /// straight into it rather than making the user go and find it.
    public let suggestedMethodID: String?

    public init(
        kind: Kind,
        headline: String,
        detail: String,
        paramKey: BrewParamKey? = nil,
        newValue: Double? = nil,
        newGrinderSetting: Double? = nil,
        suggestedMethodID: String? = nil
    ) {
        self.kind = kind
        self.headline = headline
        self.detail = detail
        self.paramKey = paramKey
        self.newValue = newValue
        self.newGrinderSetting = newGrinderSetting
        self.suggestedMethodID = suggestedMethodID
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
        case .coolerWater: return "brewing cooler"
        case .steepLonger: return "steeping longer"
        case .steepShorter: return "steeping shorter"
        case .blendWater: return "changing your water"
        case .tryDifferentMethod: return "switching brewer"
        case .none: return "changing nothing"
        }
    }

    public static let none = Adjustment(
        kind: .none,
        headline: "Change nothing",
        detail: "Brew it exactly the same way."
    )
}

/// What the engine hands back.
///
/// Tier enforcement is structural rather than conventional: a `.guided` method
/// **cannot** produce a `Diagnosis`, because there is no path through this type
/// that lets it. A screen can't opt a method into a precision the engine never
/// produced, because the value it would need doesn't exist.
public enum DiagnosisOutcome: Hashable, Sendable {
    /// Tier 1 only.
    case diagnosis(Diagnosis)
    /// Tier 2. Observations about the *brewer*, never about this cup.
    case methodNotes(MethodNotes)
    /// Tier 3. There was no brew to reason about.
    case unsupported

    public var diagnosis: Diagnosis? {
        if case let .diagnosis(value) = self { return value }
        return nil
    }

    public var methodNotes: MethodNotes? {
        if case let .methodNotes(value) = self { return value }
        return nil
    }
}

/// Tier 2 output. Deliberately a different type from `Diagnosis` so that no view
/// can render one as the other by accident — the shapes don't line up, which is
/// the point.
public struct MethodNotes: Codable, Hashable, Sendable, Identifiable {
    public var id: String { methodID }

    public struct Note: Codable, Hashable, Sendable {
        public let title: String
        public let body: String
        public let conceptID: String?

        public init(title: String, body: String, conceptID: String? = nil) {
            self.title = title
            self.body = body
            self.conceptID = conceptID
        }
    }

    public let methodID: String
    /// Names the limit out loud. Saying "we don't diagnose this yet" is what buys
    /// the trust; a confident paragraph that turns out to be generic costs more
    /// than silence.
    public let headline: String
    public let notes: [Note]

    public init(methodID: String, headline: String, notes: [Note]) {
        self.methodID = methodID
        self.headline = headline
        self.notes = notes
    }
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
