import ActivityKit
import WidgetKit
import SwiftUI
import CoffeeKit

/// The Live Activity is what makes the guided brew survive the real world — a
/// locked screen, an incoming call, someone checking a message mid-pour.
///
/// The clock is rendered with `Text(timerInterval:)` off a date rather than
/// pushed from the app. The system animates the seconds itself, which means no
/// push notifications, no background execution, and no drift: the timer keeps
/// counting even while the app is suspended.
struct BrewLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BrewActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(WidgetTheme.paper)
                .activitySystemActionForegroundColor(WidgetTheme.water)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Elapsed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        clock(context.state, font: .system(.title2, design: .rounded).weight(.semibold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Pour to")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(BrewMath.formatGrams(context.state.cumulativeTargetGrams))
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundStyle(WidgetTheme.water)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.instruction)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        ProgressView(value: context.state.progress)
                            .tint(WidgetTheme.water)
                        Text("Step \(context.state.stepIndex + 1) of \(context.state.stepCount) · \(context.attributes.recipeName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(WidgetTheme.water)
            } compactTrailing: {
                clock(context.state, font: .system(.caption, design: .rounded).weight(.medium))
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(WidgetTheme.water)
            }
            .keylineTint(WidgetTheme.water)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<BrewActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                clock(context.state, font: .system(size: 34, design: .rounded).weight(.semibold))
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(BrewMath.formatGrams(context.state.cumulativeTargetGrams))
                        .font(.system(size: 28, design: .rounded).weight(.semibold))
                        .foregroundStyle(WidgetTheme.water)
                        .monospacedDigit()
                    Text("/ \(BrewMath.formatGrams(context.state.totalWaterGrams))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Text(context.state.instruction)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: context.state.progress)
                .tint(WidgetTheme.water)

            HStack {
                Text(context.attributes.recipeName)
                if let bean = context.attributes.beanName {
                    Text("·")
                    Text(bean)
                }
                Spacer()
                if context.state.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    /// Paused freezes the display at the recorded elapsed time — a timer interval
    /// can't be stopped mid-flight, so we swap to a static string instead of
    /// letting the clock keep running behind a "Paused" label.
    private func clock(_ state: BrewActivityAttributes.ContentState, font: Font) -> some View {
        Group {
            if state.isPaused || state.isComplete {
                Text(BrewMath.formatSeconds(Int(state.pausedElapsed)))
            } else {
                Text(
                    timerInterval: state.effectiveStartDate...state.effectiveStartDate.addingTimeInterval(3600),
                    pauseTime: nil,
                    countsDown: false,
                    showsHours: false
                )
            }
        }
        .font(font)
        .monospacedDigit()
    }
}
