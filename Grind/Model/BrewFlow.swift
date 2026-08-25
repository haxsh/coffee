import Foundation
import Observation
import CoffeeKit

/// Presentation state for the things that sit *above* the tab bar.
///
/// The guided brew is a full-screen cover — you are in a brew, not browsing — and
/// the concept card is a sheet reachable from anywhere, including over a running
/// timer. Holding both here rather than inside a tab is what lets a lesson, a
/// journal entry and a diagnosis all open the same concept the same way.
@Observable
@MainActor
final class BrewFlow {
    var session: BrewSession?
    /// Set when a brew finishes. Presents the log sheet.
    var brewToLog: Brew?
    /// Set after logging a tier 1 brew. Presents Next Time.
    var brewToDiagnose: Brew?
    /// Set after logging a tier 2 brew. Presents Method Notes — a different
    /// screen, deliberately, so the two can never be confused.
    var methodNotes: MethodNotes?
    /// The globally-presented concept card.
    var conceptID: String?
    /// A method the app suggested — presented so "try a French press" is a route
    /// rather than a sentence.
    var methodToOpen: BrewMethod?
    /// Which tab is showing.
    var selectedTab: RootTab = .brew

    func showConcept(_ id: String?) {
        guard let id, Concepts.concept(id: id) != nil else { return }
        conceptID = id
    }
}

enum RootTab: Hashable {
    case brew, learn, beans, journal
}
