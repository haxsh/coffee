import WidgetKit
import SwiftUI
import AppIntents

/// A Control Centre and Lock Screen control that opens straight into a brew.
///
/// Cheap to add once `StartBrewIntent` exists for the Brew Again widget, and it
/// puts the app one press away from the place people actually reach for their
/// phone in a kitchen — without unlocking, hunting for an icon, or navigating.
struct StartBrewControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.haxsh.grind.control.startbrew") {
            ControlWidgetButton(action: StartBrewIntent(recipeID: nil)) {
                Label("Start a brew", systemImage: "cup.and.saucer.fill")
            }
        }
        .displayName("Start a brew")
        .description("Open Grind and set up your next brew.")
    }
}
