import WidgetKit
import SwiftUI
import Intents
import HealthKit

struct Provider: TimelineProvider{
    
    typealias Entry = StepEntry
    
    @AppStorage("countStep", store: UserDefaults(suiteName: "group.com.tryyyyy.Steps-Count"))
    var countStep: Int = 0
    
    func placeholder(in context: Context) -> StepEntry {
        let entry = StepEntry(date: Date(), steps: countStep)
        return entry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()){
        let entry = StepEntry(steps: countStep)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()){
        let entry = StepEntry(steps: countStep)
        completion(Timeline(entries: [entry], policy: .atEnd))
        
    }
}

struct StepEntry: TimelineEntry{
    var date: Date = Date()
    var steps: Int
}

struct StepCounterWidgetEntryView : View {
    let entry: Provider.Entry

    var body: some View {
        ZStack{
            Image("black")
                .scaledToFill()
            
            Image("run")
                
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 160)
                
            VStack{
                Text("STEP")
                    .font(Font.custom("PoetsenOne-Regular", size: 13))
                Text("\(entry.steps)")
                    .font(Font.custom("PoetsenOne-Regular", size: 18))
                    
            }
            .offset(x: 35, y: 35)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)

        }
        .edgesIgnoringSafeArea(.all)
    }
}

@main
struct StepWidget: Widget{
    private let kind = "StepWidget"
    
    var body: some WidgetConfiguration{
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepCounterWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
    }
}

