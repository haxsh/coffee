import Foundation

/// How deeply the app supports a method.
///
/// This is the field that makes breadth affordable, and it is an *honesty
/// constraint expressed as a type*: it is enforced in the engine, not only in the
/// UI, so a screen can never opt a method into a precision it doesn't have.
public enum SupportTier: String, Codable, Hashable, Sendable, CaseIterable {
    /// Recipes, guided timer, log, and a full per-symptom diagnosis with one
    /// adjustment. Needs its own rule table and expert review.
    case full
    /// Recipes, guided timer, log — and method-level notes afterwards, never a
    /// diagnosis of *this* cup.
    case guided
    /// An overview card. No timer, no log, nothing to reason about.
    case reference

    public var canBrew: Bool { self != .reference }
    public var canDiagnose: Bool { self == .full }

    public var label: String {
        switch self {
        case .full: return "Full support"
        case .guided: return "Guided"
        case .reference: return "Reference"
        }
    }
}

/// The honest axes a beginner actually decides on when picking a method.
/// Ordinal 1...5, and deliberately few — a comparison table with eleven columns
/// is a spec sheet, not a decision aid.
public struct MethodProfile: Codable, Hashable, Sendable {
    /// 1 = press a button, 5 = you are the machine.
    public let effort: Int
    /// 1 = under two minutes, 5 = hours.
    public let time: Int
    /// 1 = you probably own it, 5 = a serious purchase.
    public let gearCost: Int
    /// 1 = hard to get wrong, 5 = punishes every mistake.
    ///
    /// Named for the direction the numbers actually run. "Forgiveness" was the
    /// original label and it pointed the opposite way to its own values, which is
    /// the kind of thing that survives review and then quietly mislabels a meter.
    public let fussiness: Int
    /// Taste doesn't rank, so it gets words instead of a meter.
    public let tastesLike: String
    /// Whether this method can be made without a grinder at all.
    public let worksWithPreGround: Bool

    public init(effort: Int, time: Int, gearCost: Int, fussiness: Int, tastesLike: String, worksWithPreGround: Bool) {
        self.effort = effort
        self.time = time
        self.gearCost = gearCost
        self.fussiness = fussiness
        self.tastesLike = tastesLike
        self.worksWithPreGround = worksWithPreGround
    }
}

public struct BrewMethod: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let blurb: String
    public let symbolName: String
    /// How far this method's branch goes. See `SupportTier`.
    public let supportTier: SupportTier
    /// The five axes the Method Explorer compares on.
    public let profile: MethodProfile
    /// Whether milk is a normal part of this drink. Scopes the milk question to
    /// moka, South Indian filter and espresso rather than asking it about a V60.
    public let takesMilk: Bool
    /// The variables this method actually has. Empty for `.reference` methods —
    /// there is no brew to parameterise.
    public let paramSchema: [ParamDef]
    /// Total brew time we expect. Outside this band is itself a diagnostic signal.
    public let expectedTotalSeconds: ClosedRange<Int>
    public let conceptIDs: [String]
    public let isLocked: Bool

    public init(
        id: String,
        name: String,
        blurb: String,
        symbolName: String,
        supportTier: SupportTier,
        profile: MethodProfile,
        takesMilk: Bool = false,
        paramSchema: [ParamDef] = [],
        expectedTotalSeconds: ClosedRange<Int>,
        conceptIDs: [String] = [],
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.symbolName = symbolName
        self.supportTier = supportTier
        self.profile = profile
        self.takesMilk = takesMilk
        self.paramSchema = paramSchema
        self.expectedTotalSeconds = expectedTotalSeconds
        self.conceptIDs = conceptIDs
        self.isLocked = isLocked
    }

    public func param(_ key: BrewParamKey) -> ParamDef? {
        paramSchema.first { $0.key == key }
    }

    public var canBrew: Bool { supportTier.canBrew }
    public var canDiagnose: Bool { supportTier.canDiagnose }

    public var defaultParameters: BrewParameters {
        var params = BrewParameters()
        for def in paramSchema { params[def.key] = def.defaultValue }
        return params
    }
}
