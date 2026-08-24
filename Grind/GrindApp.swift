import SwiftUI
import CoffeeKit

@main
struct GrindApp: App {
    @State private var model = AppModel()
    @State private var flow = BrewFlow()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(flow)
                .tint(Theme.water)
        }
    }
}
