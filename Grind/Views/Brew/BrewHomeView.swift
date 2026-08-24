import SwiftUI
import CoffeeKit

/// The default tab, because the job is "I'm at the counter, help me now" — not
/// "browse a library". It opens with one tap to the thing you're most likely
/// about to do.
struct BrewHomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(BrewFlow.self) private var flow
    @State private var setupRecipe: Recipe?
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    brewAgainCard
                    recipeSection
                    methodSection
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("Brew")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Profile and settings")
                }
            }
            .sheet(isPresented: $showingProfile) { ProfileView() }
            .sheet(item: $setupRecipe) { recipe in
                BrewSetupView(recipe: recipe)
            }
            // Widget taps and Control Centre presses land here.
            .onReceive(NotificationCenter.default.publisher(for: .grindStartBrewRequested)) { note in
                let id = note.userInfo?["recipeID"] as? String
                setupRecipe = model.recipe(id: id) ?? model.suggestedRecipe
            }
        }
    }

    private var brewAgainCard: some View {
        let recipe = model.suggestedRecipe
        let pending = model.pendingAdjustment(forMethod: recipe.methodID)
        let bean = model.bean(id: model.data.lastBeanID)

        return Button {
            setupRecipe = recipe
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.lastBrew == nil ? "Start here" : "Brew again").sectionLabel()

                Text(recipe.name)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 10) {
                    Label(BrewMath.formatGrams(recipe.dose), systemImage: "scalemass")
                    Label(BrewMath.formatRatio(recipe.ratio), systemImage: "drop")
                    if let bean {
                        Label(bean.name, systemImage: "bag").lineLimit(1)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.muted)

                if let pending {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                        Text("\(pending.adjustment.headline) — \(pending.adjustment.detail)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.water)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.water.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("V60 recipes").sectionLabel()
            ForEach(model.allRecipes.filter { $0.methodID == BuiltInContent.v60.id }) { recipe in
                Button { setupRecipe = recipe } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(recipe.name).font(.headline).foregroundStyle(Theme.ink)
                            Text(recipe.blurb)
                                .font(.footnote)
                                .foregroundStyle(Theme.muted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Text(BrewMath.formatSeconds(recipe.totalSeconds))
                            .font(.caption.monospacedDigit())
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

    /// Locked methods are shown with a badge, never hidden. Hiding paid content
    /// means users never learn the app has it.
    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other methods").sectionLabel()
            ForEach(BuiltInContent.lockedMethods) { method in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(method.name).font(.headline).foregroundStyle(Theme.muted)
                        Text(method.blurb)
                            .font(.footnote)
                            .foregroundStyle(Theme.faint)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.faint)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .cardBackground()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(method.name), not yet available")
            }
        }
    }
}
