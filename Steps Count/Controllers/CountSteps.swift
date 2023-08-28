import SwiftUI
import HealthKit

struct CountSteps: View {

    @AppStorage("countStep", store: UserDefaults(suiteName: "group.com.tryyyyy.Steps-Count"))
    var countStep: Int = 0

    let healthStore = HKHealthStore()

    @State private var stepCount: Int = 0
    @State private var sleepHours: Int = 0
    @State private var sleepAlert = false
    @State private var stepsAlert = false
    @State private var sleepValue = ""
    @State private var stepsValue = ""

    var body: some View {
        VStack(spacing: 4) {
            dataSection(title: "Sleep", value: "\(sleepHours) hr", alertText: "Enter Sleep Hours", valueBinding: $sleepValue, action: fetchSleep)
                .padding(.bottom, 70)
            dataSection(title: "Steps", value: "\(stepCount)", alertText: "Enter Step Count", valueBinding: $stepsValue, action: submit)
        }
        .onAppear {
            requestAuthorization()
            fetchStepCount()
            fetchSleep()
        }
        .padding()
    }

    func dataSection(title: String, value: String, alertText: String, valueBinding: Binding<String>, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2)
            Text(value)
                .font(.title3)
            Button("Add \(title)") {
                if title == "Sleep" {
                    sleepAlert.toggle()
                } else {
                    stepsAlert.toggle()
                }
            }
            .alert("Add \(title)", isPresented: title == "Sleep" ? $sleepAlert : $stepsAlert) {
                TextField("Enter \(alertText)", text: valueBinding)
                Button("OK", action: action)
            } message: {
                Text("Enter the number of \(title.lowercased()) to add.")
            }
        }
    }

    func saveStepCountToHealthKit() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let steps = Double(stepsValue) else {
            return
        }

        let countUnit = HKUnit.count()
        let stepCountQuantity = HKQuantity(unit: countUnit, doubleValue: steps)
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
        guard let enteredValue = Int(stepsValue) else {
            print("Invalid input: \(stepsValue)")
            return
        }

        stepCount += enteredValue
        saveStepCountToHealthKit()
    }

    func requestAuthorization() {
        let readTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount),
                             HKObjectType.categoryType(forIdentifier: .sleepAnalysis)].compactMap { $0 })

        healthStore.requestAuthorization(toShare: [], read: readTypes) { (success, error) in
            if error != nil {
                print("Not authorized to use HealthKit.")
            } else if success {
                print("Authorization granted.")
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
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    let duration = Int(sample.endDate.timeIntervalSince(sample.startDate))
                    sleepDuration += duration
                }
            }

            // Convert seconds to hours
            sleepHours = sleepDuration / 3600
        }
        healthStore.execute(query)
    }

    func fetchStepCount() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
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
                stepCount = steps
                countStep = steps
            } else {
                stepCount = 0
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
