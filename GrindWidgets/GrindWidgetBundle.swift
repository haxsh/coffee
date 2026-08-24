import WidgetKit
import SwiftUI

@main
struct GrindWidgetBundle: WidgetBundle {
    var body: some Widget {
        BrewAgainWidget()
        BeanFreshnessWidget()
        BrewLiveActivity()
        StartBrewControl()
    }
}
