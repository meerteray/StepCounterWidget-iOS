import SwiftUI
import HealthKit
import WidgetKit

struct CountSteps: View {
    
    @AppStorage("countStep", store: UserDefaults(suiteName: "group.com.tryyyyy.Steps-Count"))
    var countStep: Int = 0
    
    let healtStore = HKHealthStore()
   @State var stepCount: Int = 0
    
    var body: some View {
        
      VStack(spacing: 4){
          
          Text("STEPS")
              .font(.title3)
          Text("\(stepCount)")
              .font(.title2)
      }
      .onAppear{
            self.requestAuth()
            self.fetchStepCount()
        }

        .padding()
    }
    
    func requestAuth(){
        _ = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let shareType = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!])
        let readType = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        healtStore.requestAuthorization(toShare: shareType, read: readType) { (success, error) in
            if error != nil {
                print("not authorized to use healthkit")
            }
            else if success{
                print("Request granted")
            }
        }
    }
    
    func fetchStepCount(){
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predict = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predict, options: .cumulativeSum){
            (query, result, error) in
            if let error = error{
                print("error fetching record for steps \(error.localizedDescription)")
                return
            }
            guard let result = result else{
                print("no steps count avaiable for specific predicate")
                return
            }
            
            if let sum = result.sumQuantity(){
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                self.stepCount = steps
                self.countStep = steps
            }else{
                self.stepCount = 0
               
                
            }
        }
        healtStore.execute(query)
    }
}

struct CountSteps_Previews: PreviewProvider {
    static var previews: some View {
        CountSteps()
    }
}
