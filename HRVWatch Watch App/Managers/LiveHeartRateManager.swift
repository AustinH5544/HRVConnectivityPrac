import HealthKit
import WatchConnectivity
import SwiftUI

#if os(watchOS)
import HealthKit
#endif

class LiveHeartRateManager: NSObject, ObservableObject {
    static let shared = LiveHeartRateManager()
    
    private let healthStore = HKHealthStore()
    private var anchor: HKQueryAnchor?
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    // For watchOS: track the workout start date.
    #if os(watchOS)
    private var workoutSession: HKWorkoutSession?
    private var workoutStartDate: Date?
    #endif
    
    @Published var latestHeartRate: Double?
    
    /// Starts live heart rate updates using an anchored object query.
    func startLiveUpdates() {
        #if os(watchOS)
        startWorkoutSession()
        #endif
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available.")
            return
        }
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type is not available.")
            return
        }
        
        // On watchOS, use the workout start date to filter samples.
        #if os(watchOS)
        let startDate = workoutStartDate ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        #else
        let predicate: NSPredicate? = nil
        #endif
        
        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: predicate,
                                          anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, newAnchor, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error in initial live update query: \(error.localizedDescription)")
                return
            }
            self.anchor = newAnchor
            self.processSamples(samples)
        }
        
        query.updateHandler = { [weak self] (query, samples, deletedObjects, newAnchor, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error in live update query update: \(error.localizedDescription)")
                return
            }
            self.anchor = newAnchor
            self.processSamples(samples)
        }
        
        healthStore.execute(query)
        self.heartRateQuery = query
        print("Started live heart rate updates.")
    }
    
    /// Stops the live heart rate updates.
    func stopLiveUpdates() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("Stopped live heart rate updates.")
        }
        #if os(watchOS)
        stopWorkoutSession()
        #endif
    }
    
    /// Processes the received heart rate samples and sends them to the iOS device.
    private func processSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        for sample in samples {
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("❤️ Live Heart Rate: \(Int(heartRate)) BPM")
            DispatchQueue.main.async {
                self.latestHeartRate = heartRate
                DataSender.shared.sendHeartRateData(heartRate: heartRate)
            }
        }
    }
    
    // MARK: - Workout Session (for watchOS)
    #if os(watchOS)
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.delegate = self  // If needed, you can implement HKWorkoutSessionDelegate methods.
            let now = Date()
            workoutSession?.startActivity(with: now)
            workoutStartDate = now
            print("Workout session started on watch at \(now).")
        } catch {
            print("❌ Failed to start workout session: \(error.localizedDescription)")
        }
    }
    
    private func stopWorkoutSession() {
        workoutSession?.end()
        workoutSession = nil
        print("Workout session stopped on watch.")
    }
    #endif
}

// Optionally, if you want to implement HKWorkoutSessionDelegate on watchOS,
// you can extend LiveHeartRateManager with that protocol.
#if os(watchOS)
extension LiveHeartRateManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session changed to state: \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session error: \(error.localizedDescription)")
    }
}
#endif

