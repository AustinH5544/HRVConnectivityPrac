import HealthKit

class HealthKitManager: NSObject, HKWorkoutSessionDelegate {
    let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutDataSource: HKLiveWorkoutDataSource?
    private var anchor: HKQueryAnchor?

    // MARK: - Request Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"]))
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            if success {
                self.enableBackgroundDelivery()
                self.startWorkoutSession() // Ensure continuous heart rate updates
                self.startLiveHeartRateUpdates() // Start real-time heart rate updates
            }
            completion(success, error)
        }
    }

    // MARK: - Enable Background Delivery
    private func enableBackgroundDelivery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery enabled for heart rate")
            } else {
                print("❌ Failed to enable background delivery: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // MARK: - Start Workout Session
    func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.delegate = self

            // Use HKLiveWorkoutDataSource for live tracking
            workoutDataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            workoutSession?.startActivity(with: Date())
            print("✅ Workout session started successfully")

        } catch {
            print("❌ Failed to create workout session: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Workout Session
    func stopWorkoutSession() {
        workoutSession?.end()
        print("⏹ Workout session stopped.")
    }

    // MARK: - Workout Session Delegate Methods
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("🏃‍♂️ Workout session is now running.")
            startLiveHeartRateUpdates()  // Ensure updates continue when workout starts
        case .ended:
            print("⏹ Workout session ended.")
        default:
            print("ℹ️ Workout session state changed to: \(toState.rawValue)")
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session error: \(error.localizedDescription)")
    }

    // MARK: - Start Live Heart Rate Updates
    // MARK: - Start Live Heart Rate Updates
    func startLiveHeartRateUpdates(completion: ((Double?, Error?) -> Void)? = nil) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion?(nil, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Heart rate type not available"]))
            return
        }

        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                completion?(nil, error)
                return
            }

            self.anchor = newAnchor

            if let samples = samples as? [HKQuantitySample], let sample = samples.last {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                print("❤️ Live Heart Rate: \(Int(heartRate)) BPM")
                completion?(heartRate, nil)
            }
        }

        // Ensure continuous updates in background
        query.updateHandler = { query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                completion?(nil, error)
                return
            }

            self.anchor = newAnchor

            if let samples = samples as? [HKQuantitySample], let sample = samples.last {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                print("❤️ Updated Heart Rate: \(Int(heartRate)) BPM")
                completion?(heartRate, nil)
            }
        }

        healthStore.execute(query) // ✅ Ensure query is executed!
    }

}
