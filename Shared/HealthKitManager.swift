import HealthKit

class HealthKitManager {
    let healthStore = HKHealthStore()
    
    // Request authorization to access heart rate data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            completion(success, error)
        }
    }

    // Fetch the most recent heart rate sample
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let samples = samples as? [HKQuantitySample],
                  let sample = samples.first else {
                completion(nil, nil)
                return
            }
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate, nil)
        }
        healthStore.execute(query)
    }

    // Live heart rate updates using an observer query
    func startLiveHeartRateUpdates(completion: @escaping (Double?, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate type not available"]))
            return
        }
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                completion(nil, error)
                return
            }
            self?.fetchLatestHeartRate { heartRate, error in
                completion(heartRate, error)
            }
            completionHandler()
        }
        healthStore.execute(query)
    }
}
