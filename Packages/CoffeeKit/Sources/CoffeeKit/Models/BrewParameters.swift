import Foundation

/// The variables a brew can have. Which of these are *meaningful* is declared
/// per-method by `BrewMethod.paramSchema` — pour-over has no `pressure`,
/// espresso has no `bloomWater`.
///
/// This indirection is why adding espresso later is an addition rather than a
/// migration. See docs/02-content-model.md, IA risk #1.
public enum BrewParamKey: String, Codable, Hashable, Sendable, CaseIterable {
    /// Levers the brew setup screen can pre-fill from an adjustment.
    ///
    /// **The engine must never return an adjustment keyed on anything outside
    /// this set**, or the user is handed advice, taps "save this for next time",
    /// and nothing happens — which is worse than no advice, because it looks like
    /// it worked. `DiagnosisEngineTests` enforces the containment.
    public static var userAdjustable: Set<BrewParamKey> {
        [.dose, .ratio, .waterTemp, .grind, .steepTime]
    }

    case dose            // grams of coffee
    case ratio           // 1:N — water is always derived, never stored
    case waterTemp       // celsius
    case grind           // normalised coarseness, 0 (finest) ... 100 (coarsest)
    case bloomWater      // grams
    case bloomTime       // seconds
    case steepTime       // seconds — immersion's primary lever, where pour-over has grind
    case yield           // grams out (espresso)
    case pressure        // bars (espresso)
    case shotTime        // seconds (espresso)
}

/// A method-scoped bag of brew variables.
///
/// Backed by `[String: Double]` rather than `[BrewParamKey: Double]` so the
/// encoded JSON is a plain object (Swift encodes non-String-keyed dictionaries
/// as a flat alternating array, which is unreadable in an export file).
public struct BrewParameters: Codable, Hashable, Sendable {
    private var storage: [String: Double]

    public init() { self.storage = [:] }

    public init(_ values: [BrewParamKey: Double]) {
        self.storage = Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) })
    }

    public subscript(key: BrewParamKey) -> Double? {
        get { storage[key.rawValue] }
        set { storage[key.rawValue] = newValue }
    }

    /// Non-optional read for callers that have a sensible fallback.
    public func value(_ key: BrewParamKey, default fallback: Double) -> Double {
        storage[key.rawValue] ?? fallback
    }

    public var isEmpty: Bool { storage.isEmpty }

    public var keys: [BrewParamKey] {
        storage.keys.compactMap(BrewParamKey.init(rawValue:))
    }

    /// Keys whose values differ between two parameter sets, ignoring
    /// floating-point noise. Drives the planned-vs-actual diff on Brew Detail.
    public func changedKeys(comparedTo other: BrewParameters) -> [BrewParamKey] {
        let allKeys = Set(storage.keys).union(other.storage.keys)
        return allKeys.compactMap { raw -> BrewParamKey? in
            guard let key = BrewParamKey(rawValue: raw) else { return nil }
            let mine = storage[raw]
            let theirs = other.storage[raw]
            switch (mine, theirs) {
            case (nil, nil): return nil
            case let (lhs?, rhs?): return abs(lhs - rhs) > 0.0001 ? key : nil
            default: return key
            }
        }.sorted { $0.rawValue < $1.rawValue }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.storage = try container.decode([String: Double].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}

/// Declares that a method *has* a variable, and the bounds a UI should respect.
public struct ParamDef: Codable, Hashable, Sendable, Identifiable {
    public enum Unit: String, Codable, Sendable {
        case grams, ratio, celsius, seconds, coarseness, bars
    }

    public var id: BrewParamKey { key }
    public let key: BrewParamKey
    public let unit: Unit
    public let minimum: Double
    public let maximum: Double
    public let step: Double
    public let defaultValue: Double

    public init(key: BrewParamKey, unit: Unit, minimum: Double, maximum: Double, step: Double, defaultValue: Double) {
        self.key = key
        self.unit = unit
        self.minimum = minimum
        self.maximum = maximum
        self.step = step
        self.defaultValue = defaultValue
    }

    public func clamp(_ value: Double) -> Double {
        min(max(value, minimum), maximum)
    }
}
