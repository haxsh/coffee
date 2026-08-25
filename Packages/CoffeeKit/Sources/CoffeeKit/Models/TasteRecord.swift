import Foundation

/// Deliberately tiny. Every field added here costs seconds against the
/// 30-second logging budget, and logging is the single point of failure for the
/// entire product. See docs/00-product-brief.md, counter-metrics.
public struct TasteRecord: Codable, Hashable, Sendable {
    /// 1...5
    public var rating: Int
    /// **Black coffee only.** -2 (very sour / sharp) ... 0 (balanced) ... +2 (bitter / drying)
    ///
    /// Meaningless when the drink has milk in it — see `milkCharacter`.
    public var extraction: Int
    /// -2 (thin / watery) ... 0 (just right) ... +2 (heavy / muddy)
    public var strength: Int
    /// **Milk drinks only.** -2 (harsh / burnt) ... 0 (smooth) ... +2 (flat / dull)
    ///
    /// Milk fat and protein bind to exactly the compounds that read as acidity and
    /// bitterness, so a milk drinker cannot reliably place a cup on sour ↔ bitter.
    /// Asking anyway would take a tap and discard the answer. The log screen swaps
    /// the axis rather than suppressing it: same position, same one tap, but a
    /// question that can actually be answered.
    ///
    /// The scale is coarser than `extraction` and honestly so — harsh points at
    /// over-extraction or too dark a roast, flat points at under-strength.
    public var milkCharacter: Int
    public var descriptors: [Descriptor]
    public var note: String?

    public init(
        rating: Int,
        extraction: Int = 0,
        strength: Int = 0,
        milkCharacter: Int = 0,
        descriptors: [Descriptor] = [],
        note: String? = nil
    ) {
        self.rating = min(max(rating, 1), 5)
        self.extraction = min(max(extraction, -2), 2)
        self.strength = min(max(strength, -2), 2)
        self.milkCharacter = min(max(milkCharacter, -2), 2)
        self.descriptors = descriptors
        self.note = note
    }

    /// Whether the cup landed where it should, on whichever axis was actually asked.
    public func isBalanced(withMilk: Bool) -> Bool {
        withMilk ? (milkCharacter == 0 && strength == 0) : (extraction == 0 && strength == 0)
    }

    /// Black-coffee convenience, kept because most call sites are black coffee.
    public var isBalanced: Bool { isBalanced(withMilk: false) }

    /// Records logged before the milk axis existed decode as 0 rather than failing.
    private enum CodingKeys: String, CodingKey {
        case rating, extraction, strength, milkCharacter, descriptors, note
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rating = try c.decode(Int.self, forKey: .rating)
        extraction = try c.decode(Int.self, forKey: .extraction)
        strength = try c.decode(Int.self, forKey: .strength)
        milkCharacter = try c.decodeIfPresent(Int.self, forKey: .milkCharacter) ?? 0
        descriptors = try c.decodeIfPresent([Descriptor].self, forKey: .descriptors) ?? []
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }
}

/// Fixed vocabulary. Never free-text-first: free text can't be diagnosed, and a
/// blank box intimidates exactly the beginner we're trying to serve.
public enum Descriptor: String, Codable, Hashable, Sendable, CaseIterable {
    case sweet, juicy, sharp, drying, flat, muddy, teaLike, syrupy, papery, ashy, hollow, balanced, silty, burnt

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
        case .silty: return "fines"
        case .burnt: return "roast-level"
        }
    }

    /// Descriptors that, on their own, point at a bag rather than a technique.
    public static let stalingSignals: Set<Descriptor> = [.flat, .papery]

    /// Grit in the cup. An immersion-specific signal: it points at fines and the
    /// plunge, not at extraction, so it is diagnosed separately.
    public static let siltSignals: Set<Descriptor> = [.silty, .muddy]

    /// Descriptors a milk drinker can actually use. Sour and juicy are not among
    /// them — milk masks both.
    public static let milkVocabulary: [Descriptor] = [
        .sweet, .syrupy, .burnt, .ashy, .flat, .teaLike, .drying, .balanced
    ]

    public static let blackVocabulary: [Descriptor] = allCases.filter { $0 != .burnt && $0 != .silty }
}
