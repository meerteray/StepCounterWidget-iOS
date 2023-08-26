import WidgetKit
import SwiftUI

struct StepCounterWidgetBundle: WidgetBundle {
    var body: some Widget {
        StepWidget()
        StepCounterWidgetLiveActivity()
    }
}
