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
    @State private var exploring = false

    var body: some View {
        NavigationStack {
            Group {
                if showExplorer {
                    MethodExplorerView()
                } else {
                    continueState
                }
            }
            .navigationTitle(showExplorer ? "Explore" : "Brew")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // One root, two states — never a modal, never buried. Which
                    // one opens is decided by whether the user has brewed before,
                    // which is the two-loop model expressed as navigation.
                    Button(showExplorer ? "Brewing" : "Explore") {
                        withAnimation(.easeInOut(duration: 0.2)) { exploring.toggle() }
                    }
                    .disabled(model.data.brews.isEmpty)
                    .opacity(model.data.brews.isEmpty ? 0 : 1)
                }
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
            .onReceive(NotificationCenter.default.publisher(for: .grindStartBrewRequested)) { note in
                let id = note.userInfo?["recipeID"] as? String
                setupRecipe = model.recipe(id: id) ?? model.suggestedRecipe
            }
        }
    }

    /// A user with no history has nothing to continue, and their real first
    /// question is "what should I even try?" — so the same tab answers that
    /// instead.
    private var showExplorer: Bool { model.data.brews.isEmpty || exploring }

    private var continueState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                brewAgainCard
                yourMethods
                exploreCard
            }
            .padding(20)
        }
        .background(Theme.paper)
    }

    /// Progress toward the handoff, shown per method. Never frames trying
    /// something else as a failure — exploring is the other half of the product.
    private var yourMethods: some View {
        let counts = Dictionary(grouping: model.data.brews, by: \.methodID)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        return VStack(alignment: .leading, spacing: 10) {
            if !counts.isEmpty {
                Text("Your methods").sectionLabel()
                ForEach(counts, id: \.key) { entry in
                    if let method = BuiltInContent.method(id: entry.key) {
                        NavigationLink { MethodDetailView(method: method) } label: {
                            HStack {
                                Text(method.name).font(.headline).foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(entry.value) brew\(entry.value == 1 ? "" : "s")")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Theme.muted)
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundStyle(Theme.faint)
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
    }

    private var exploreCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { exploring = true }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.grid.2x2")
                    .font(.title3)
                    .foregroundStyle(Theme.water)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try something else")
                        .font(.headline).foregroundStyle(Theme.ink)
                    Text("\(BuiltInContent.methods.count) ways to make coffee, compared honestly")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.faint)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .cardBackground()
        }
        .buttonStyle(.plain)
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

}
