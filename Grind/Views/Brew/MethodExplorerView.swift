import SwiftUI
import CoffeeKit

/// S29 — the exploration loop's only home, and the first screen a new user sees.
///
/// Context is a couch or a commute, phone held close, full attention. This screen
/// deliberately does **not** inherit the guided brew's constraints — that one is
/// doing, this one is reading, and designing it for wet hands would waste the one
/// place in the app where density is affordable.
struct MethodExplorerView: View {
    @Environment(AppModel.self) private var model

    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all, canBrewNow, quick, easy
        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: return "All"
            case .canBrewNow: return "What I own"
            case .quick: return "Under 5 min"
            case .easy: return "Easy"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                shelf
                filters
                methodList
            }
            .padding(20)
        }
        .background(Theme.paper)
    }

    // MARK: - The shelf

    /// The exploration loop's progress object: a record of what you've made.
    /// It never breaks, never lapses and never nags — which is exactly what
    /// separates it from a streak.
    @ViewBuilder private var shelf: some View {
        let tried = model.methodsTried
        if !tried.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("You've made").sectionLabel()
                    Spacer()
                    Text("\(tried.count) of \(BuiltInContent.brewableMethods.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.faint)
                }
                FlowRow(spacing: 8) {
                    ForEach(BuiltInContent.methods.filter { tried.contains($0.id) }) { method in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text(method.name).font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Theme.target)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.target.opacity(0.12), in: Capsule())
                    }
                }
                if let progress = handoffLine {
                    Text(progress)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBackground()
        }
    }

    /// Surfaces progress toward settling on one method — never framing a second
    /// method as a failure. Exploring is the point of this screen.
    private var handoffLine: String? {
        let counts = Dictionary(grouping: model.data.brews, by: \.methodID).mapValues(\.count)
        guard let best = counts.max(by: { $0.value < $1.value }), best.value >= 2 else { return nil }
        let name = BuiltInContent.method(id: best.key)?.name ?? best.key
        return best.value >= 5
            ? "\(best.value) brews on \(name) — you're getting somewhere with it."
            : "\(best.value) brews on \(name). A few more and it starts getting easier to dial in."
    }

    // MARK: - Filters

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { option in
                    let selected = filter == option
                    Button {
                        filter = option
                    } label: {
                        Text(option.label)
                            .font(.subheadline)
                            .foregroundStyle(selected ? .white : Theme.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 36)
                            .background(selected ? Theme.water : Theme.surfaceAlt, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - The list

    private var methodList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(filter == .all ? "Ways to make coffee" : filter.label).sectionLabel()
            ForEach(sortedMethods) { method in
                NavigationLink {
                    MethodDetailView(method: method)
                } label: {
                    MethodRow(method: method, tried: model.methodsTried.contains(method.id))
                }
                .buttonStyle(.plain)
            }
            if sortedMethods.isEmpty {
                Text("Nothing matches that filter yet.")
                    .font(.callout)
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 20)
            }
        }
    }

    /// Default order is **what this user can most likely make today**, from the
    /// gear they told us about. Not alphabetical, and deliberately not tier-first —
    /// leading with the fully supported methods would read as a paywall, which is
    /// exactly what tiering must not become.
    private var sortedMethods: [BrewMethod] {
        let preGround = model.data.buysPreGround
        return BuiltInContent.methods
            .filter(matchesFilter)
            .sorted { lhs, rhs in
                let l = reachability(lhs, preGround: preGround)
                let r = reachability(rhs, preGround: preGround)
                if l != r { return l > r }
                return lhs.profile.gearCost < rhs.profile.gearCost
            }
    }

    private func reachability(_ method: BrewMethod, preGround: Bool) -> Int {
        var score = 0
        if method.canBrew { score += 2 }
        if !preGround || method.profile.worksWithPreGround { score += 2 }
        score += (6 - method.profile.gearCost)
        return score
    }

    private func matchesFilter(_ method: BrewMethod) -> Bool {
        switch filter {
        case .all: return true
        case .canBrewNow:
            return method.canBrew && (!model.data.buysPreGround || method.profile.worksWithPreGround)
        case .quick: return method.profile.time <= 2
        case .easy: return method.profile.fussiness <= 2
        }
    }
}

// MARK: - Row

struct MethodRow: View {
    let method: BrewMethod
    let tried: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(method.name)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                if tried {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.target)
                        .accessibilityLabel("You've made this")
                }
                Spacer()
                TierBadge(tier: method.supportTier)
            }

            Text(method.profile.tastesLike)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Meter(label: "Effort", value: method.profile.effort)
                Meter(label: "Time", value: method.profile.time)
                Meter(label: "Cost", value: method.profile.gearCost)
                Meter(label: "Fuss", value: method.profile.fussiness)
            }

            HStack(spacing: 6) {
                Image(systemName: method.canBrew ? "play.circle" : "book")
                    .font(.caption)
                Text(method.canBrew ? "Start a brew" : "Learn about this")
                    .font(.caption.weight(.medium))
                Spacer()
                if method.profile.worksWithPreGround {
                    Text("no grinder needed")
                        .font(.caption2)
                        .foregroundStyle(Theme.faint)
                }
            }
            .foregroundStyle(method.canBrew ? Theme.water : Theme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [method.name]
        if tried { parts.append("you've made this") }
        parts.append(method.profile.tastesLike)
        parts.append(method.canBrew ? "can be brewed in the app" : "reference only")
        return parts.joined(separator: ". ")
    }
}

/// Four ordinal axes as small meters. The fifth — what it tastes like — gets
/// words instead, because taste doesn't rank.
struct Meter: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(Theme.faint)
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { step in
                    Capsule()
                        .fill(step <= value ? Theme.water.opacity(0.75) : Theme.line)
                        .frame(width: 7, height: 4)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value) out of 5")
    }
}

/// Visible, but never framed as a lock. A reference method isn't withheld — it's
/// undescribed, and saying so is the whole point of tiering.
struct TierBadge: View {
    let tier: SupportTier

    var body: some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .textCase(.uppercase)
            .tracking(0.7)
            .foregroundStyle(colour)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(colour.opacity(0.14), in: Capsule())
    }

    private var text: String {
        switch tier {
        case .full: return "Full advice"
        case .guided: return "Guided"
        case .reference: return "Read only"
        }
    }

    private var colour: Color {
        switch tier {
        case .full: return Theme.target
        case .guided: return Theme.water
        case .reference: return Theme.muted
        }
    }
}

/// Wrapping row layout for the shelf. iOS 16+ Layout, so no manual geometry maths.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
