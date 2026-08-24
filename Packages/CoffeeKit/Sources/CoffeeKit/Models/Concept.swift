import Foundation

/// The learning atom, and the spine of the whole product.
///
/// One record, many entry points: any technical term anywhere in the app —
/// a recipe step, a diagnosis, a tasting descriptor, a lesson — resolves to a
/// Concept and presents it identically. This is what makes learning ambient
/// rather than a destination you have to remember to visit.
public struct Concept: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let term: String
    /// The one-line answer. Never more than a sentence.
    public let shortDefinition: String
    /// Roughly sixty seconds of reading.
    public let card: String
    public let relatedConceptIDs: [String]
    public let lessonID: String?

    public init(
        id: String,
        term: String,
        shortDefinition: String,
        card: String,
        relatedConceptIDs: [String] = [],
        lessonID: String? = nil
    ) {
        self.id = id
        self.term = term
        self.shortDefinition = shortDefinition
        self.card = card
        self.relatedConceptIDs = relatedConceptIDs
        self.lessonID = lessonID
    }
}
