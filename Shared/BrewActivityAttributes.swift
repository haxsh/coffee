import ActivityKit
import Foundation

/// The Live Activity contract, compiled into both the app and the widget
/// extension.
///
/// This lives in `Shared/` rather than in CoffeeKit so that CoffeeKit stays pure
/// Foundation and can be built and tested anywhere — including plain
/// `swift test` on a machine with no iOS SDK. ActivityKit would drag an iOS-only
/// dependency into the one part of the codebase that benefits most from not
/// having any.
struct BrewActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var stepIndex: Int
        var stepCount: Int
        var stepKind: String
        var instruction: String
        /// What the scale should read at the end of this step.
        var cumulativeTargetGrams: Double
        var totalWaterGrams: Double
        /// When the brew started, adjusted for any time spent paused.
        ///
        /// The Live Activity renders its clock with `Text(timerInterval:)` off
        /// this date, so the system animates the seconds itself. No push updates,
        /// no background execution, no drift — and the timer keeps counting on a
        /// locked screen even if the app is suspended.
        var effectiveStartDate: Date
        var isPaused: Bool
        /// Frozen elapsed time to display while paused, since a timer interval
        /// can't be stopped mid-flight.
        var pausedElapsed: TimeInterval
        var isComplete: Bool

        var progress: Double {
            guard stepCount > 0 else { return 0 }
            return min(1, Double(stepIndex) / Double(stepCount))
        }
    }

    var recipeName: String
    var methodName: String
    var beanName: String?
}
