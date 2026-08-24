import Foundation

/// Deliberately tiny. Every field added here costs seconds against the
/// 30-second logging budget, and logging is the single point of failure for the
/// entire product. See docs/00-product-brief.md, counter-metrics.
public struct TasteRecord: Codable, Hashable, Sendable {
    /// 1...5
    public var rating: Int
    /// -2 (very sour / sharp) ... 0 (balanced) ... +2 (bitter / drying)
    public var extraction: Int
    /// -2 (thin / watery) ... 0 (just right) ... +2 (heavy / muddy)
    public var strength: Int
    public var descriptors: [Descriptor]
    public var note: String?

    public init(
        rating: Int,
        extraction: Int = 0,
        strength: Int = 0,
        descriptors: [Descriptor] = [],
        note: String? = nil
    ) {
        self.rating = min(max(rating, 1), 5)
        self.extraction = min(max(extraction, -2), 2)
        self.strength = min(max(strength, -2), 2)
        self.descriptors = descriptors
        self.note = note
    }

    public var isBalanced: Bool { extraction == 0 && strength == 0 }
}

/// Fixed vocabulary. Never free-text-first: free text can't be diagnosed, and a
/// blank box intimidates exactly the beginner we're trying to serve.
public enum Descriptor: String, Codable, Hashable, Sendable, CaseIterable {
    case sweet, juicy, sharp, drying, flat, muddy, teaLike, syrupy, papery, ashy, hollow, balanced

    public var label: String {
        switch self {
        case .teaLike: return "tea-like"
        default: return rawValue
        }
    }

    /// The concept this descriptor teaches when long-pressed.
    public var conceptID: String? {
        switch self {
        case .sharp, .hollow: return "under-extraction"
        case .drying, .ashy: return "over-extraction"
        case .flat, .papery: return "staling"
        case .muddy, .syrupy: return "strength"
        case .teaLike: return "strength"
        case .sweet, .juicy, .balanced: return "extraction"
        }
    }

    /// Descriptors that, on their own, point at a bag rather than a technique.
    public static let stalingSignals: Set<Descriptor> = [.flat, .papery]
}
