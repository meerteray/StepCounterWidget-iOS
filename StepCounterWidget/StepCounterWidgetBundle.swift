//
//  StepCounterWidgetBundle.swift
//  StepCounterWidget
//
//  Created by Mert Eray on 23.08.2023.
//

import WidgetKit
import SwiftUI

@main
struct StepCounterWidgetBundle: WidgetBundle {
    var body: some Widget {
        StepCounterWidget()
        StepCounterWidgetLiveActivity()
    }
}
