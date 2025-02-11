import HealthKit

class LiveHeartRateManager: HeartRateProvider {
    private let healthKitManager = HealthKitManager()
    private var lastHeartRate: Double?
    
    var currentHeartRate: Double? {
        return lastHeartRate
    }

    func startMonitoring() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                self.healthKitManager.startWorkoutSession()
                self.startLiveHeartRateUpdates()
            }
        }
    }
    
    func stopMonitoring() {
        healthKitManager.stopWorkoutSession()
    }

    private func startLiveHeartRateUpdates() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, _, newAnchor, error in
            if let samples = samples as? [HKQuantitySample], let sample = samples.last {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.lastHeartRate = heartRate
                print("❤️ Live Heart Rate: \(Int(heartRate)) BPM")
            }
        }

        healthKitManager.healthStore.execute(query)
    }
}
