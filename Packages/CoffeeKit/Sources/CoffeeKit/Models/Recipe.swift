import Foundation

public struct RecipeStep: Identifiable, Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case bloom, pour, swirl, wait, drawdown, press

        public var isPour: Bool { self == .bloom || self == .pour }
    }

    public let id: String
    public let kind: Kind
    public let startSeconds: Int
    public let durationSeconds: Int
    /// Cumulative water at the *end* of this step, as a fraction of total water.
    /// Stored as a fraction so scaling to any dose is exact rather than rounded.
    /// `nil` for steps that don't pour — the running total carries forward.
    public let cumulativeWaterFraction: Double?
    public let instruction: String
    public let conceptID: String?

    public init(
        id: String,
        kind: Kind,
        startSeconds: Int,
        durationSeconds: Int,
        cumulativeWaterFraction: Double? = nil,
        instruction: String,
        conceptID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.startSeconds = startSeconds
        self.durationSeconds = durationSeconds
        self.cumulativeWaterFraction = cumulativeWaterFraction
        self.instruction = instruction
        self.conceptID = conceptID
    }

    public var endSeconds: Int { startSeconds + durationSeconds }
}

public struct Recipe: Identifiable, Codable, Hashable, Sendable {
    public enum Author: String, Codable, Sendable { case builtIn, user }

    public let id: String
    public let methodID: String
    public var name: String
    public var blurb: String
    public var author: Author
    public var parameters: BrewParameters
    public var steps: [RecipeStep]
    public var conceptIDs: [String]
    public var isLocked: Bool

    public init(
        id: String,
        methodID: String,
        name: String,
        blurb: String,
        author: Author = .builtIn,
        parameters: BrewParameters,
        steps: [RecipeStep],
        conceptIDs: [String] = [],
        isLocked: Bool = false
    ) {
        self.id = id
        self.methodID = methodID
        self.name = name
        self.blurb = blurb
        self.author = author
        self.parameters = parameters
        self.steps = steps
        self.conceptIDs = conceptIDs
        self.isLocked = isLocked
    }

    public var totalSeconds: Int { steps.map(\.endSeconds).max() ?? 0 }

    public var dose: Double { parameters.value(.dose, default: 15) }
    public var ratio: Double { parameters.value(.ratio, default: 16) }
    public var totalWater: Double { BrewMath.water(dose: dose, ratio: ratio) }
}
