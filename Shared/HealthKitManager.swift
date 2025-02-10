import HealthKit

// This version of HealthKitManager uses HKWorkoutSession and HKLiveWorkoutBuilder
// to start a workout session when the app launches.
class HealthKitManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    let healthStore = HKHealthStore()
    
    // Workout session and builder properties
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?
    var onHeartRateUpdate: ((Double) -> Void)?

    
    // Request authorization for both heart rate and workout data.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Make sure we request read permissions for both heart rate and workout types.
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, NSError(domain: "HealthKitManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Heart rate type not available"]))
            return
        }
        let workoutType = HKObjectType.workoutType()

        
        let typesToRead: Set<HKObjectType> = [heartRateType, workoutType]
        // No types to share in this example.
        let typesToShare: Set<HKSampleType> = []
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
    
    // Call this function to start the workout session and begin live data collection.
    func startWorkout() {
        // Configure a workout session. You can customize the activityType and locationType as needed.
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running    // Change as needed.
        configuration.locationType = .outdoor       // Change as needed.
        
        do {
            // Create a workout session and obtain the associated builder.
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
        } catch {
            print("Error creating workout session: \(error)")
            return
        }
        
        // Set delegates
        workoutSession?.delegate = self
        workoutBuilder?.delegate = self
        
        // Set the data source for the workout builder.
        if let builder = workoutBuilder {
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        }
        
        // Start the session and begin data collection.
        let startDate = Date()
        workoutSession?.startActivity(with: startDate)
        workoutBuilder?.beginCollection(withStart: startDate) { success, error in
            if success {
                print("Workout session started successfully at \(startDate)")
            } else if let error = error {
                print("Error starting workout collection: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - HKWorkoutSessionDelegate Methods
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("Workout session changed state from \(fromState) to \(toState) at \(date)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error)")
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate Methods
    
    // Called when new data is collected.
    // Inside the workout builder delegate method:
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        // Loop over each sample type collected.
        for sampleType in types {
            // Check if the sample type is the heart rate type.
            if let quantityType = sampleType as? HKQuantityType,
               quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                
                // Try to get the statistics for heart rate.
                if let statistics = workoutBuilder.statistics(for: quantityType) {
                    // Define the unit for heart rate: count per minute.
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    // Get the average heart rate from the statistics.
                    if let newHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) {
                        // Call the update closure with the new heart rate.
                        onHeartRateUpdate?(newHeartRate)
                    }
                }
            }
        }
    }


    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if necessary.
        print("Workout builder collected an event.")
    }
    
    // Optional: End the workout when needed.
    func endWorkout(completion: @escaping () -> Void) {
        let endDate = Date()
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: endDate) { success, error in
            if let error = error {
                print("Error ending collection: \(error)")
            }
            self.workoutBuilder?.finishWorkout { workout, error in
                if let error = error {
                    print("Error finishing workout: \(error)")
                } else {
                    print("Workout ended successfully.")
                }
                completion()
            }
        }
    }
}
