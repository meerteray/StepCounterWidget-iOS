import SwiftUI
import HealthKit
import WidgetKit

struct CountSteps: View {
    
    @AppStorage("countStep", store: UserDefaults(suiteName: "group.com.tryyyyy.Steps-Count"))
    var countStep: Int = 0
    
    let healthStore = HKHealthStore()
    
    @State private var stepCount: Int = 0
    @State private var sleepHours: Int = 0
    @State private var sleepAlert = false
    @State private var stepsAlert = false
    @State private var sleepValue = ""
    @State private var stepsvalue = ""

    var body: some View {
        VStack(spacing: 4) {
            
            //Sleep
            Text("Sleep")
                .font(.title2)
            Text("\(sleepHours) hr")
                .font(.title3)
            Button("Add Sleep") {
                sleepAlert.toggle()
            }
            .alert("Add Sleep", isPresented: $sleepAlert) {
                TextField("Enter Sleep Hours", text: $sleepValue)
                Button("OK", action: {})
            } message: {
                Text("Enter the number of hours to add.")
            }
            
            .padding(.bottom, 70)
            //Steps
            Text("Steps")
                .font(.title2)
            Text("\(stepCount)")
                .font(.title3)
            Button("Add Step") {
                stepsAlert.toggle()
            }
            .alert("Add Step", isPresented: $stepsAlert) {
                TextField("Enter Step Count", text: $stepsvalue)
                Button("OK", action: submit)
            } message: {
                Text("Enter the number of steps to add.")
            }
        }
        .onAppear {
            self.requestAuth()
            self.fetchStepCount()
            self.fetchSleep()
        }
        .padding()
    }
    
    func saveStepCountToHealthKit() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let countUnit = HKUnit.count()
        print("1984 3 ", stepCount)
        let stepCountQuantity = HKQuantity(unit: countUnit, doubleValue: Double(stepsvalue)!)
        print("1984 4" , stepCount)
        let stepCountSample = HKQuantitySample(
            type: stepCountType,
            quantity: stepCountQuantity,
            start: Date(),
            end: Date()
        )

        healthStore.save(stepCountSample) { (success, error) in
            if let error = error {
                print("Error writing step count: \(error.localizedDescription)")
            } else {
                print("Step count data written successfully!")
            }
        }
    }

    func submit() {
        guard let enteredValue = Int(stepsvalue) else {
            print("Invalid input: \(stepsvalue)")
            return
        }
        
        stepCount += enteredValue
        print("1984 1" , stepCount)
        saveStepCountToHealthKit()
        print("1984 2" , stepCount)
    }
    
    func requestAuth(){
       
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        let shareTypes: Set<HKSampleType> = [stepCountType]
        let readTypes: Set<HKObjectType> = [stepCountType, sleepType]
         
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if error != nil {
                print("Not authorized to use HealthKit.")
            } else if success {
                print("Authorization granted.")
            }
        }                                       //nil
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if error != nil {
                print("Not authorized to access sleep data.")
            } else if success {
                print("Authorization granted for sleep data.")
            }
        }
    }
    
    func fetchSleep() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                print("No sleep data available for specific predicate.")
                return
            }
            
            var sleepDuration = 0
            for sample in samples {
                let sleepValue = sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue
                if sleepValue {
                    let duration = Int(sample.endDate.timeIntervalSince(sample.startDate))
                    sleepDuration += duration
                }
            }
            
            // Convert seconds to hours
            let sleepHours = sleepDuration / 3600
            self.sleepHours = sleepHours
        }
        healthStore.execute(query)
    }

    func fetchStepCount(){
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predict = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predict, options: .cumulativeSum) { (query, result, error) in
            if let error = error {
                print("Error fetching record for steps: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else {
                print("No step count available for specific predicate.")
                return
            }
            
            if let sum = result.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                self.stepCount = steps
                self.countStep = steps
            } else {
                self.stepCount = 0
            }
        }
        healthStore.execute(query)
    }
}

struct CountSteps_Previews: PreviewProvider {
    static var previews: some View {
        CountSteps()
    }
}
