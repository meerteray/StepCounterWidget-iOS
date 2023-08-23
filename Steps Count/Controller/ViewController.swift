import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stepsData: UILabel!
    
        let healthStore = HKHealthStore()

        override func viewDidLoad() {
            super.viewDidLoad()
            requestAuthorization()
        }

        func requestAuthorization() {
            guard HKHealthStore.isHealthDataAvailable() else {
                print("Health data is not available on this device.")
                return
            }

            let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!

            healthStore.requestAuthorization(toShare: nil, read: [stepCountType]) { success, error in
                if success {
                    // Authorization successful, fetch and display data
                    self.fetchPedometerData()
                } else {
                    print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        func fetchPedometerData() {
            let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!

            let query = HKSampleQuery(sampleType: stepCountType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
                if let error = error {
                    print("Query error: \(error.localizedDescription)")
                    return
                }

                if let quantitySamples = results as? [HKQuantitySample] {
                    var totalSteps = 0
                    for sample in quantitySamples {
                        totalSteps += Int(sample.quantity.doubleValue(for: HKUnit.count()))
                    }

                    DispatchQueue.main.async {
                        print(totalSteps)
                        self.stepsData.text = String(totalSteps)
                    }
                }
            }

            healthStore.execute(query)
        }
}


