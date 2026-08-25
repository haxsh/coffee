import SwiftUI
import CoffeeKit

/// One screen, three shapes — because the tree is deliberately ragged. A tier 1
/// or 2 method offers recipes and a brew; a tier 3 method is a leaf and says so.
///
/// The reference case is the one that needs care: **never a disabled Start
/// button.** A greyed control reads as broken; an absent one with a sentence of
/// explanation reads as honest. And it always offers a way onward, because a
/// branch that just ends is a dead end.
struct MethodDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow

    let method: BrewMethod
    @State private var setupRecipe: Recipe?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                profileGrid

                if method.canBrew {
                    recipeSection
                } else {
                    referenceSection
                }

                conceptSection

                if !brewsWithThisMethod.isEmpty {
                    historySection
                }
            }
            .padding(20)
        }
        .background(Theme.paper)
        .navigationTitle(method.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $setupRecipe) { BrewSetupView(recipe: $0) }
        .safeAreaInset(edge: .bottom) {
            if method.canBrew, let recipe = BuiltInContent.gentlestRecipe(forMethod: method.id) {
                Button(hasTried ? "Brew this again" : "Start a brew") {
                    // A first attempt on an unfamiliar brewer gets the gentlest
                    // recipe, not the highest-clarity one.
                    setupRecipe = hasTried ? (BuiltInContent.recipes(forMethod: method.id).first ?? recipe) : recipe
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
    }

    private var hasTried: Bool { model.methodsTried.contains(method.id) }
    private var brewsWithThisMethod: [Brew] {
        model.brewsNewestFirst.filter { $0.methodID == method.id }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TierBadge(tier: method.supportTier)
                if hasTried {
                    Label("You've made this", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.target)
                }
            }
            Text(method.blurb)
                .font(.callout)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(method.profile.tastesLike)
                .font(.callout.italic())
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var profileGrid: some View {
        HStack(spacing: 18) {
            Meter(label: "Effort", value: method.profile.effort)
            Meter(label: "Time", value: method.profile.time)
            Meter(label: "Cost", value: method.profile.gearCost)
            Meter(label: "Fuss", value: method.profile.fussiness)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recipes").sectionLabel()
            ForEach(BuiltInContent.recipes(forMethod: method.id)) { recipe in
                Button { setupRecipe = recipe } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(recipe.name).font(.headline).foregroundStyle(Theme.ink)
                            Spacer()
                            Text(BrewMath.formatSeconds(recipe.totalSeconds))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.faint)
                        }
                        Text(recipe.blurb)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .cardBackground()
                }
                .buttonStyle(.plain)
            }

            if method.supportTier == .guided {
                // Never let a tier 2 method imply the precision of a tier 1 one —
                // this is the disclosure that keeps the promise honest, made
                // before the brew rather than after it.
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle").font(.caption)
                    Text("We'll time this one for you, but we don't diagnose it yet — afterwards you'll get notes on the method rather than advice about your specific cup.")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
            }
        }
    }

    /// The tier 3 leaf. Says what it can't do, in words, and routes onward.
    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let concept = method.conceptIDs.compactMap(Concepts.concept(id:)).first {
                Text(concept.card)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(Theme.ink.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("We can't coach you through this one")
                    .font(.subheadline.weight(.semibold))
                Text(reasonWeCannotCoach)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("Methods you can brew here").sectionLabel()
                ForEach(onwardSuggestions) { suggestion in
                    NavigationLink {
                        MethodDetailView(method: suggestion)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.name).font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.ink)
                                Text(suggestion.profile.tastesLike)
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.faint)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .cardBackground()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var reasonWeCannotCoach: String {
        switch method.id {
        case "coldbrew":
            return "You taste the result twelve hours after every decision, so the brew-taste-adjust loop this app runs on can't turn over. We'd rather say that than pretend."
        case "espresso":
            return "Espresso has its own variables and its own ways of going wrong. It needs a diagnosis model of its own, and doing that badly would be worse than not doing it."
        case "instant":
            return "There's no extraction happening at your kettle — you're rehydrating coffee that was brewed in a factory. None of the advice in this app applies."
        default:
            return "We can tell you about it, but we don't have the recipes or the failure modes worked out well enough to coach you through it yet."
        }
    }

    /// Two brewable methods with a comparable character, so the branch routes
    /// back into doing rather than just ending.
    private var onwardSuggestions: [BrewMethod] {
        BuiltInContent.brewableMethods
            .filter { !model.data.buysPreGround || $0.profile.worksWithPreGround }
            .sorted { abs($0.profile.effort - method.profile.effort) < abs($1.profile.effort - method.profile.effort) }
            .prefix(2)
            .map { $0 }
    }

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let concepts = method.conceptIDs.compactMap(Concepts.concept(id:))
                .filter { method.canBrew || $0.id != method.conceptIDs.first }
            if !concepts.isEmpty {
                Text("Worth knowing").sectionLabel()
                ForEach(concepts) { concept in
                    Button { flow.showConcept(concept.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(concept.term).font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.water)
                                Text(concept.shortDefinition)
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your brews").sectionLabel()
            ForEach(brewsWithThisMethod.prefix(5)) { brew in
                NavigationLink { BrewDetailView(brew: brew) } label: { BrewRow(brew: brew) }
            }
        }
    }
}
