import HealthKit

class HealthKitManager: NSObject, HKWorkoutSessionDelegate {
    let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutDataSource: HKLiveWorkoutDataSource?
    
    // MARK: - Request Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"]))
            return
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Heart rate type not available"]))
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            if success {
                self.enableBackgroundDelivery()
                self.startWorkoutSession()
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
              HKQuantityType.quantityType(forIdentifier: .heartRate) != nil else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.delegate = self
            
            // Use HKLiveWorkoutDataSource for live tracking (if needed for additional data)
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
    
    // MARK: - HKWorkoutSessionDelegate Methods
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("🏃‍♂️ Workout session is now running.")
        case .ended:
            print("⏹ Workout session ended.")
        default:
            print("ℹ️ Workout session changed to state: \(toState.rawValue)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session error: \(error.localizedDescription)")
    }
}
