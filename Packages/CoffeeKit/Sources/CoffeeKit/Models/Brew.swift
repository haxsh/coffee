import Foundation

/// One execution of a recipe. The irreplaceable object — everything else in the
/// app can be re-downloaded, so this is what export and backup exist to protect.
public struct Brew: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var startedAt: Date
    public var methodID: String
    public var recipeID: String?
    /// Nullable by design. Never block a brew on inventory data.
    public var beanID: UUID?

    /// What actually happened.
    public var params: BrewParameters
    /// Snapshot of the recipe at brew time, so later recipe edits don't rewrite
    /// history. Drives the planned-vs-actual diff on Brew Detail.
    public var plannedParams: BrewParameters

    public var grinderID: UUID?
    /// The setting in the user's own units, as they set it.
    public var grinderSetting: Double?

    /// Frozen at brew time — a bean's age changes every day, so a diagnosis run
    /// later would otherwise disagree with the one the user was shown.
    public var beanRestDays: Int?
    public var beanFreshness: Freshness?

    public var actualTotalSeconds: Int?
    public var taste: TasteRecord?
    public var diagnosis: Diagnosis?
    /// Set when this brew applied the adjustment suggested by an earlier one.
    /// The loop metric lives here.
    public var adjustedFromBrewID: UUID?
    public var note: String?

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        methodID: String,
        recipeID: String? = nil,
        beanID: UUID? = nil,
        params: BrewParameters = BrewParameters(),
        plannedParams: BrewParameters = BrewParameters(),
        grinderID: UUID? = nil,
        grinderSetting: Double? = nil,
        beanRestDays: Int? = nil,
        beanFreshness: Freshness? = nil,
        actualTotalSeconds: Int? = nil,
        taste: TasteRecord? = nil,
        diagnosis: Diagnosis? = nil,
        adjustedFromBrewID: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.methodID = methodID
        self.recipeID = recipeID
        self.beanID = beanID
        self.params = params
        self.plannedParams = plannedParams
        self.grinderID = grinderID
        self.grinderSetting = grinderSetting
        self.beanRestDays = beanRestDays
        self.beanFreshness = beanFreshness
        self.actualTotalSeconds = actualTotalSeconds
        self.taste = taste
        self.diagnosis = diagnosis
        self.adjustedFromBrewID = adjustedFromBrewID
        self.note = note
    }

    public var isLogged: Bool { taste != nil }
    public var dose: Double { params.value(.dose, default: 15) }
    public var ratio: Double { params.value(.ratio, default: 16) }
    public var totalWater: Double { BrewMath.water(dose: dose, ratio: ratio) }
}

/// The adjustment a user chose to carry into their next brew. Written when they
/// tap "Save this for next time" on Next Time; consumed and cleared by Brew Setup.
public struct PendingAdjustment: Codable, Hashable, Sendable {
    public let sourceBrewID: UUID
    public let methodID: String
    public let adjustment: Adjustment
    public let createdAt: Date

    public init(sourceBrewID: UUID, methodID: String, adjustment: Adjustment, createdAt: Date = Date()) {
        self.sourceBrewID = sourceBrewID
        self.methodID = methodID
        self.adjustment = adjustment
        self.createdAt = createdAt
    }
}

/// The result of comparing a brew against the one it was adjusted from.
/// This is the payoff moment — the app proving it was worth listening to.
public enum LoopOutcome: Equatable, Sendable {
    case improved(from: Int, to: Int, change: String)
    case unchanged(rating: Int, change: String)
    case worse(from: Int, to: Int, change: String)

    public var headline: String {
        switch self {
        case .improved: return "That worked."
        case .unchanged: return "No change in the cup."
        case .worse: return "That went the wrong way."
        }
    }

    public var detail: String {
        switch self {
        case let .improved(from, to, change):
            return "\(from)★ → \(to)★ after \(change). Keep it there."
        case let .unchanged(rating, change):
            return "Still \(rating)★ after \(change). Try one more step in the same direction."
        case let .worse(from, to, change):
            return "\(from)★ → \(to)★ after \(change). Go back to where you were."
        }
    }
}
