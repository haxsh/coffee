import WidgetKit
import SwiftUI
import AppIntents
import CoffeeKit

/// The highest-value widget in the set: your last recipe, your bean, and any
/// pending grind adjustment — one tap into the guided brew.
///
/// It exists to remove the cold-launch browse. The whole promise of the loop is
/// that yesterday's decision is already applied when you get to the counter, and
/// this is where that promise is visible before you even open the app.
struct BrewAgainWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.haxsh.grind.widget.brewagain", provider: SnapshotProvider()) { entry in
            BrewAgainView(snapshot: entry.snapshot)
                .containerBackground(WidgetTheme.paper, for: .widget)
        }
        .configurationDisplayName("Brew again")
        .description("Your last brew, with any adjustment already waiting.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BrewAgainView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    var body: some View {
        if let brew = snapshot.lastBrew {
            content(brew)
        } else {
            emptyState
        }
    }

    private func content(_ brew: BrewSummary) -> some View {
        Button(intent: StartBrewIntent(recipeID: brew.recipeID)) {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
                Text("Brew again")
                    .font(.system(.caption2, design: .monospaced).weight(.medium))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(WidgetTheme.muted)

                Text(brew.recipeName)
                    .font(.system(family == .systemSmall ? .headline : .title3, design: .rounded).weight(.bold))
                    .foregroundStyle(WidgetTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if let bean = brew.beanName {
                    Text(bean)
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                if let adjustment = snapshot.pendingAdjustment {
                    adjustmentBadge(adjustment)
                } else {
                    Label("Start", systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.water)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }

    /// The pending adjustment is the point. On a medium widget it gets the full
    /// "18 → 16 clicks"; on a small one, just the instruction — a truncated
    /// number is worse than no number.
    private func adjustmentBadge(_ adjustment: AdjustmentSummary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
                .font(.caption2)
            VStack(alignment: .leading, spacing: 1) {
                Text(adjustment.headline)
                    .font(.caption.weight(.semibold))
                if family != .systemSmall {
                    Text(adjustment.detail)
                        .font(.caption2)
                        .foregroundStyle(WidgetTheme.muted)
                        .lineLimit(1)
                }
            }
        }
        .foregroundStyle(WidgetTheme.water)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(WidgetTheme.water.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyState: some View {
        Button(intent: StartBrewIntent(recipeID: nil)) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "cup.and.saucer")
                    .font(.title3)
                    .foregroundStyle(WidgetTheme.water)
                Spacer(minLength: 0)
                Text("Start your first brew")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(WidgetTheme.ink)
                Text("About four minutes.")
                    .font(.caption2)
                    .foregroundStyle(WidgetTheme.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}
