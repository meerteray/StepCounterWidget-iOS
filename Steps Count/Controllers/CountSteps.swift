import SwiftUI
import HealthKit
import WidgetKit

struct CountSteps: View {
    
    @AppStorage("countStep", store: UserDefaults(suiteName: "group.com.tryyyyy.Steps-Count"))
    var countStep: Int = 0
    
    let healthStore = HKHealthStore()
    
    @State private var stepCount: Int = 0
    @State private var showingAlert = false
    @State private var value = ""

    var body: some View {
        VStack(spacing: 4) {
            Text("STEPS")
                .font(.title3)
            Text("\(stepCount)")
                .font(.title2)
            
            Button("Add Step") {
                showingAlert.toggle()
            }
            .alert("Add Step", isPresented: $showingAlert) {
                TextField("Enter Step Count", text: $value)
                Button("OK", action: submit)
            } message: {
                Text("Enter the number of steps to add.")
            }
        }
        .onAppear {
            self.requestAuth()
            self.fetchStepCount()
        }
        .padding()
    }
    
    func saveStepCountToHealthKit() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let countUnit = HKUnit.count()
        print("1984 3 ", stepCount)
        let stepCountQuantity = HKQuantity(unit: countUnit, doubleValue: Double(value)!)
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
        guard let enteredValue = Int(value) else {
            print("Invalid input: \(value)")
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
        
        let shareTypes: Set<HKSampleType> = [stepCountType]
        let readTypes: Set<HKObjectType> = [stepCountType]
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if error != nil {
                print("Not authorized to use HealthKit.")
            } else if success {
                print("Authorization granted.")
            }
        }
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
