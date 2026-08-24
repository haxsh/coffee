import WidgetKit
import SwiftUI
import AppIntents
import CoffeeKit

/// Rest days on the bag currently on your shelf.
///
/// Glanceable on the home screen, and genuinely useful on the Lock Screen: "is
/// this ready yet" is a question people ask away from the counter, standing in
/// front of the cupboard.
struct BeanFreshnessWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.haxsh.grind.widget.beanfreshness", provider: SnapshotProvider()) { entry in
            BeanFreshnessView(bean: entry.snapshot.activeBean)
                .containerBackground(WidgetTheme.paper, for: .widget)
        }
        .configurationDisplayName("Bean freshness")
        .description("How long your current bag has been off roast.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct BeanFreshnessView: View {
    @Environment(\.widgetFamily) private var family
    let bean: BeanSummary?

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(inlineText)
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        default:
            small
        }
    }

    private var inlineText: String {
        guard let bean, let days = bean.restDays else { return "No coffee tracked" }
        return "\(bean.name) · day \(days)"
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(bean?.restDays.map(String.init) ?? "—")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("days")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccessible(label: accessibilityText)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(bean?.name ?? "No coffee tracked")
                .font(.headline)
                .lineLimit(1)
            if let bean, let freshness = bean.freshness, let days = bean.restDays {
                Text("\(freshness.label) · day \(days)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add a roast date").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetAccessible(label: accessibilityText)
    }

    private var small: some View {
        Group {
            if let bean {
                Button(intent: OpenBeanIntent(beanID: bean.beanID.uuidString)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(WidgetTheme.freshness(bean.freshness))
                                .frame(width: 8, height: 8)
                            Text(bean.freshness?.label ?? "Unknown")
                                .font(.system(.caption2, design: .monospaced).weight(.medium))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .foregroundStyle(WidgetTheme.muted)
                        }

                        Spacer(minLength: 0)

                        if let days = bean.restDays {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text("\(days)")
                                    .font(.system(size: 40, design: .rounded).weight(.bold))
                                    .foregroundStyle(WidgetTheme.ink)
                                Text("days")
                                    .font(.caption)
                                    .foregroundStyle(WidgetTheme.muted)
                            }
                        }

                        Text(bean.name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WidgetTheme.ink)
                            .lineLimit(1)
                        if let roaster = bean.roaster {
                            Text(roaster)
                                .font(.caption2)
                                .foregroundStyle(WidgetTheme.muted)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "bag").font(.title3).foregroundStyle(WidgetTheme.water)
                    Spacer(minLength: 0)
                    Text("Add the bag on your counter")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WidgetTheme.ink)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private var accessibilityText: String {
        guard let bean else { return "No coffee tracked" }
        guard let days = bean.restDays, let freshness = bean.freshness else {
            return "\(bean.name), no roast date"
        }
        return "\(bean.name), \(days) days off roast, \(freshness.label)"
    }
}

private extension View {
    func widgetAccessible(label: String) -> some View {
        self.accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}
