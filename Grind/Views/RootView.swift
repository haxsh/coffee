import SwiftUI
import CoffeeKit

/// Four tabs: two things you *do*, two collections you *have*.
///
/// Profile is deliberately not a tab — it's low-frequency and doesn't deserve a
/// fifth of the most valuable real estate on screen. It gets one canonical home
/// behind the avatar button, identical from every tab root.
///
/// The verb/noun mix (Brew, Learn / Beans, Journal) is a known IA smell, kept on
/// purpose and flagged for a card sort. See docs/01-ia-and-navigation.md.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var flow = flow

        Group {
            if model.data.hasOnboarded {
                TabView(selection: $flow.selectedTab) {
                    BrewHomeView()
                        .tabItem { Label("Brew", systemImage: "cup.and.saucer") }
                        .tag(RootTab.brew)

                    LearnView()
                        .tabItem { Label("Learn", systemImage: "book") }
                        .tag(RootTab.learn)

                    BeansListView()
                        .tabItem { Label("Beans", systemImage: "bag") }
                        .tag(RootTab.beans)

                    JournalListView()
                        .tabItem { Label("Journal", systemImage: "list.bullet.rectangle") }
                        .tag(RootTab.journal)
                }
            } else {
                OnboardingView()
            }
        }
        // A brew covers the tab bar entirely — you're in it, not browsing.
        .fullScreenCover(item: Binding(
            get: { flow.session.map { GuidedBrewPresentation(session: $0) } },
            set: { if $0 == nil { flow.session = nil } }
        )) { presentation in
            GuidedBrewView(session: presentation.session)
        }
        // Logging is a sheet you can drink through.
        .sheet(item: $flow.brewToLog) { brew in
            LogBrewView(brew: brew)
                .interactiveDismissDisabled(false)
        }
        .sheet(item: $flow.brewToDiagnose) { brew in
            NextTimeView(brew: brew)
        }
        // The concept card opens over everything, including a running timer.
        .sheet(item: Binding(
            get: { flow.conceptID.flatMap(Concepts.concept(id:)) },
            set: { if $0 == nil { flow.conceptID = nil } }
        )) { concept in
            ConceptCardSheet(concept: concept)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { handleDeepLink() }
        }
        .onAppear { handleDeepLink() }
    }

    /// A widget tap or a Control Centre press runs its intent in the app's own
    /// process once we're foregrounded, so the hand-off is a simple static read.
    private func handleDeepLink() {
        guard let link = DeepLink.take() else { return }
        switch link {
        case .startBrew(let recipeID):
            flow.selectedTab = .brew
            NotificationCenter.default.post(
                name: .grindStartBrewRequested,
                object: nil,
                userInfo: recipeID.map { ["recipeID": $0] }
            )
        case .openBean:
            flow.selectedTab = .beans
        }
    }
}

extension Notification.Name {
    static let grindStartBrewRequested = Notification.Name("grind.startBrewRequested")
}

/// `fullScreenCover(item:)` needs an Identifiable; BrewSession is a reference
/// type driving its own timer, so it's wrapped rather than made Identifiable
/// itself.
struct GuidedBrewPresentation: Identifiable {
    let session: BrewSession
    var id: ObjectIdentifier { ObjectIdentifier(session) }
}
