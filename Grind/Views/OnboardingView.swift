import SwiftUI
import CoffeeKit

/// Four screens, skippable at any point, run once before the tab bar exists.
///
/// Success criterion: **the first brew must not fail.** Skipping every step has
/// to produce working defaults, never a broken state — so every choice here is a
/// refinement of something that already works.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    @State private var grinder: Grinder?
    @State private var buysPreGround = false
    @State private var water: WaterSource = .unknown
    @State private var experience: Experience = .starting

    private let lastPage = 4

    enum Experience: String, CaseIterable {
        case starting = "Just started"
        case awhile = "Been at it a while"
        case dialled = "Pretty dialled in"

        var recipe: Recipe {
            switch self {
            case .starting: return BuiltInContent.forgivingV60
            case .awhile: return BuiltInContent.everydayV60
            case .dialled: return BuiltInContent.clarityV60
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                grinderPage.tag(1)
                waterPage.tag(2)
                experiencePage.tag(3)
                ready.tag(4)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page == lastPage ? "Show me what I could make" : "Continue") {
                if page == lastPage { finish() } else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 10)

            Button("Skip") { finish() }
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .frame(minHeight: 44)
        }
        .background(Theme.paper)
    }

    private var welcome: some View {
        page(
            title: "Your coffee should get better",
            body: "Brew it, tell us how it tasted, and we'll tell you the one thing to change. Then we'll have it waiting for you tomorrow.",
            icon: "arrow.triangle.2.circlepath"
        )
    }

    private var grinderPage: some View {
        VStack(spacing: 18) {
            header("What do you grind with?",
                   "So we can say \"18 → 16 clicks\" instead of \"a bit finer\".")
            VStack(spacing: 8) {
                ForEach(Grinder.knownGrinders) { known in
                    choice(known.displayName, selected: !buysPreGround && grinder?.model == known.model) {
                        grinder = known
                        buysPreGround = false
                    }
                }
                choice("A grinder, but not one of those",
                       selected: !buysPreGround && grinder?.model == Grinder.unknown.model) {
                    grinder = .unknown
                    buysPreGround = false
                }
                // A first-class answer, not an escape hatch. A large share of this
                // market buys pre-ground, and onboarding that treats that as a
                // failure state loses them on screen two. It also genuinely
                // changes the advice they'll get.
                choice("I buy it pre-ground", selected: buysPreGround) {
                    buysPreGround = true
                    grinder = nil
                }
            }
            .padding(.horizontal, 24)

            if buysPreGround {
                Text("That's completely fine. We'll give you advice you can actually act on — temperature, timing and ratio — instead of telling you to grind finer.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
        .padding(.top, 40)
    }

    /// One question, five options. The water *question* is in scope; a water
    /// *feature* — calculators, mineral profiles — is explicitly not.
    private var waterPage: some View {
        VStack(spacing: 18) {
            header("What water do you brew with?",
                   "Coffee is about 98% water, and it's the one thing nobody thinks to check.")
            VStack(spacing: 8) {
                ForEach(WaterSource.allCases, id: \.self) { source in
                    choice(source.label, selected: water == source) { water = source }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 40)
    }

    private var experiencePage: some View {
        VStack(spacing: 18) {
            header("Where are you at?",
                   "This only picks your starting recipe. You can change it whenever.")
            VStack(spacing: 8) {
                ForEach(Experience.allCases, id: \.self) { option in
                    choice(option.rawValue, selected: experience == option) { experience = option }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 40)
    }

    private var ready: some View {
        page(
            title: "You're set",
            body: readyBody,
            icon: "checkmark.circle"
        )
    }

    private var readyBody: String {
        let count = BuiltInContent.brewableMethods.count
        if buysPreGround {
            return "We'll show you \(count) ways to make coffee, with the ones that suit pre-ground first."
        }
        return "We'll show you \(count) ways to make coffee. If you're not sure where to start, \(experience.recipe.name) takes about \(BrewMath.formatSeconds(experience.recipe.totalSeconds))."
    }

    private func page(title: String, body: String, icon: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.water)
            header(title, body)
            Spacer()
        }
        .padding(.top, 70)
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func choice(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(Theme.ink)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundStyle(Theme.water) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(selected ? Theme.water.opacity(0.12) : Theme.surface,
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Theme.water : Theme.line))
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        if let grinder, !buysPreGround { model.upsertGrinder(grinder) }
        model.completeOnboarding(waterSource: water, buysPreGround: buysPreGround)
    }
}
