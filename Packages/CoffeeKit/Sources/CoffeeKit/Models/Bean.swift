import Foundation

public enum RoastLevel: String, Codable, Hashable, Sendable, CaseIterable {
    case light, medium, dark

    public var label: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .dark: return "Dark"
        }
    }

    /// Day thresholds after roast: (peak begins, fading begins, stale begins).
    ///
    /// Roast level genuinely shifts these — light roasts degas slower and hold
    /// longer, which is most of what our target user buys. Treating them all the
    /// same would misfire diagnosis rule 1 on the majority of bags.
    ///
    /// - Important: These numbers are a designer's draft (see OQ-4). They need a
    ///   roaster's review before launch. The *structure* is what matters here.
    var freshnessThresholds: (peak: Int, fading: Int, stale: Int) {
        switch self {
        case .light: return (7, 28, 45)
        case .medium: return (5, 21, 35)
        case .dark: return (3, 14, 28)
        }
    }
}

public enum Freshness: String, Codable, Hashable, Sendable {
    /// Still degassing. Results are erratic and not worth diagnosing.
    case resting
    case peak
    case fading
    case stale

    public var label: String {
        switch self {
        case .resting: return "Resting"
        case .peak: return "Peak"
        case .fading: return "Fading"
        case .stale: return "Past it"
        }
    }

    public var isDiagnosable: Bool { self != .resting }
}

public struct Bean: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var roaster: String?
    public var origin: String?
    public var process: String?
    public var varietal: String?
    public var roastLevel: RoastLevel
    /// The one optional field worth pushing for — it drives freshness and feeds
    /// diagnosis rules 1 and 2.
    public var roastDate: Date?
    public var bagWeightG: Double?
    public var roasterNotes: String?
    public var purchasedAt: Date?
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        roaster: String? = nil,
        origin: String? = nil,
        process: String? = nil,
        varietal: String? = nil,
        roastLevel: RoastLevel = .light,
        roastDate: Date? = nil,
        bagWeightG: Double? = nil,
        roasterNotes: String? = nil,
        purchasedAt: Date? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.roaster = roaster
        self.origin = origin
        self.process = process
        self.varietal = varietal
        self.roastLevel = roastLevel
        self.roastDate = roastDate
        self.bagWeightG = bagWeightG
        self.roasterNotes = roasterNotes
        self.purchasedAt = purchasedAt
        self.isArchived = isArchived
    }

    public func restDays(asOf now: Date = Date()) -> Int? {
        guard let roastDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: roastDate, to: now).day ?? 0
        return max(0, days)
    }

    public func freshness(asOf now: Date = Date()) -> Freshness? {
        guard let days = restDays(asOf: now) else { return nil }
        let t = roastLevel.freshnessThresholds
        if days < t.peak { return .resting }
        if days < t.fading { return .peak }
        if days < t.stale { return .fading }
        return .stale
    }

    public var displaySubtitle: String {
        [roaster, origin].compactMap { $0 }.joined(separator: " · ")
    }
}
