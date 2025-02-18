import HealthKit
import WatchConnectivity
import SwiftUI

#if os(watchOS)
import HealthKit
#endif

class LiveHeartRateManager: NSObject, ObservableObject {
    static let shared = LiveHeartRateManager()
    
    // Use the shared HealthKitManager instance for HealthKit work.
    private let healthKitManager = HealthKitManager()
    
    // Track the query anchor and active query.
    private var anchor: HKQueryAnchor?
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var latestHeartRate: Double?
    let hrvCalculator = HRVCalculator()
    
    /// Starts live heart rate updates using an anchored query.
    func startLiveUpdates() {
        // Request HealthKit authorization and configuration.
        // HealthKitManager.requestAuthorization will enable background delivery
        // and start a workout session if successful.
        healthKitManager.requestAuthorization { [weak self] success, error in
            guard let self = self else { return }
            guard success else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Build a predicate if on watchOS; otherwise, use nil.
            #if os(watchOS)
            // Since the workout session has already started via HealthKitManager,
            // we assume data starts from now. For more accuracy, HealthKitManager could
            // expose a workoutStartDate if needed.
            let startDate = Date()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
            #else
            let predicate: NSPredicate? = nil
            #endif
            
            // Retrieve the heart rate quantity type.
            guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                print("Heart rate type is not available.")
                return
            }
            
            // Create the anchored query.
            let query = HKAnchoredObjectQuery(type: heartRateType,
                                              predicate: predicate,
                                              anchor: self.anchor,
                                              limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, newAnchor, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error in initial live update query: \(error.localizedDescription)")
                    return
                }
                self.anchor = newAnchor
                self.processSamples(samples)
            }
            
            // Set an update handler to process new samples in real time.
            query.updateHandler = { [weak self] (query, samples, deletedObjects, newAnchor, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error in live update query update: \(error.localizedDescription)")
                    return
                }
                self.anchor = newAnchor
                self.processSamples(samples)
            }
            
            // Execute the query using HealthKitManager's healthStore.
            self.healthKitManager.healthStore.execute(query)
            self.heartRateQuery = query
            print("Started live heart rate updates.")
        }
    }
    
    /// Stops the live heart rate updates.
    func stopLiveUpdates() {
        if let query = heartRateQuery {
            healthKitManager.healthStore.stop(query)
            heartRateQuery = nil
            print("Stopped live heart rate updates.")
        }
        #if os(watchOS)
        // Stop the workout session via HealthKitManager.
        healthKitManager.stopWorkoutSession()
        #endif
    }
    
    /// Processes the received heart rate samples.
    private func processSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        for sample in samples {
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("❤️ Live Heart Rate: \(Int(heartRate)) BPM")
            DispatchQueue.main.async {
                self.latestHeartRate = heartRate
                self.hrvCalculator.addBeat(heartRate: heartRate, at: Date())
                // Evaluate HRV and detect events.
                EventDetectionManager.shared.evaluateHRV(using: self.hrvCalculator)
                // Send heart rate data to the paired device.
                DataSender.shared.sendHeartRateData(heartRate: heartRate)
            }
        }
    }
}
