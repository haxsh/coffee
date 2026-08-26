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
    /// The step whose length `BrewParamKey.steepTime` controls.
    ///
    /// Without this, "steep longer" is advice with nothing behind it: the
    /// parameter changes, the timer doesn't, and the brew is identical.
    public let isSteep: Bool

    public init(
        id: String,
        kind: Kind,
        startSeconds: Int,
        durationSeconds: Int,
        cumulativeWaterFraction: Double? = nil,
        instruction: String,
        conceptID: String? = nil,
        isSteep: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.startSeconds = startSeconds
        self.durationSeconds = durationSeconds
        self.cumulativeWaterFraction = cumulativeWaterFraction
        self.instruction = instruction
        self.conceptID = conceptID
        self.isSteep = isSteep
    }

    public var endSeconds: Int { startSeconds + durationSeconds }

    func withDuration(_ seconds: Int) -> RecipeStep {
        RecipeStep(id: id, kind: kind, startSeconds: startSeconds, durationSeconds: seconds,
                   cumulativeWaterFraction: cumulativeWaterFraction, instruction: instruction,
                   conceptID: conceptID, isSteep: isSteep)
    }

    func shifted(by seconds: Int) -> RecipeStep {
        RecipeStep(id: id, kind: kind, startSeconds: startSeconds + seconds,
                   durationSeconds: durationSeconds,
                   cumulativeWaterFraction: cumulativeWaterFraction, instruction: instruction,
                   conceptID: conceptID, isSteep: isSteep)
    }
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

    public var isImmersion: Bool { steps.contains(where: \.isSteep) }

    /// The recipe as it would actually run at a given steep time.
    ///
    /// The steep step is defined by when it *ends*, because that's what the user
    /// is timing — "four minutes" means break the crust at 4:00, not steep for
    /// four minutes after a thirty-second pour. Everything after it shifts.
    public func withSteepSeconds(_ seconds: Double) -> Recipe {
        guard let index = steps.firstIndex(where: \.isSteep) else { return self }
        let step = steps[index]
        let newDuration = max(5, Int(seconds.rounded()) - step.startSeconds)
        let delta = newDuration - step.durationSeconds
        guard delta != 0 else { return self }

        var updated = self
        updated.steps[index] = step.withDuration(newDuration)
        for i in (index + 1)..<updated.steps.count {
            updated.steps[i] = updated.steps[i].shifted(by: delta)
        }
        updated.parameters[.steepTime] = Double(step.startSeconds + newDuration)
        return updated
    }

    public var dose: Double { parameters.value(.dose, default: 15) }
    public var ratio: Double { parameters.value(.ratio, default: 16) }
    public var totalWater: Double { BrewMath.water(dose: dose, ratio: ratio) }
}
