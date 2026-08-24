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
    @State private var experience: Experience = .starting

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
                experiencePage.tag(2)
                ready.tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page == 3 ? "Let's brew one" : "Continue") {
                if page == 3 { finish() } else { withAnimation { page += 1 } }
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
                    choice(known.displayName, selected: grinder?.model == known.model) {
                        grinder = known
                    }
                }
                choice("Something else, or pre-ground", selected: grinder?.model == Grinder.unknown.model) {
                    grinder = .unknown
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
            body: "We'll start you on \(experience.recipe.name). It takes about \(BrewMath.formatSeconds(experience.recipe.totalSeconds)) — grab your scale.",
            icon: "checkmark.circle"
        )
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
        if let grinder { model.upsertGrinder(grinder) }
        model.completeOnboarding()
    }
}
