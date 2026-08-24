import AppIntents
import Foundation

/// Opens the app straight into a brew, pre-filled from the last one.
///
/// Backs three separate surfaces — the Brew Again widget, the Control Centre
/// control, and Siri — from one definition. `OpenIntent` conformance is what
/// makes the widget's tap and the control's press both foreground the app
/// rather than silently doing nothing.
struct StartBrewIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a brew"
    static var description = IntentDescription("Opens Grind and sets up your next brew, with any pending adjustment already applied.")

    /// The whole point of the widget is skipping the cold-launch browse.
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Recipe")
    var recipeID: String?

    init() {}

    init(recipeID: String?) {
        self.recipeID = recipeID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLink.pending = .startBrew(recipeID: recipeID)
        return .result()
    }
}

/// Opens the bean the widget is showing.
struct OpenBeanIntent: AppIntent {
    static var title: LocalizedStringResource = "Open coffee"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Bean")
    var beanID: String

    init() { self.beanID = "" }

    init(beanID: String) {
        self.beanID = beanID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLink.pending = .openBean(id: beanID)
        return .result()
    }
}

/// Handed between the widget process and the app on launch.
///
/// A widget tap runs `perform()` in the *app's* process once it is foregrounded,
/// so a simple static hand-off is enough — no URL scheme, no parsing.
enum DeepLink: Equatable {
    case startBrew(recipeID: String?)
    case openBean(id: String)

    /// Read and cleared by the root view when the app becomes active.
    @MainActor static var pending: DeepLink?

    @MainActor
    static func take() -> DeepLink? {
        defer { pending = nil }
        return pending
    }
}
