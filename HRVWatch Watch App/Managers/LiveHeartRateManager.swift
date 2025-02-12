import HealthKit
import WatchConnectivity
import SwiftUI

class LiveHeartRateManager: NSObject, ObservableObject {
    static let shared = LiveHeartRateManager()
    
    private let healthStore = HKHealthStore()
    private var anchor: HKQueryAnchor?
    private var heartRateQuery: HKAnchoredObjectQuery?
    // In LiveHeartRateManager.swift
    @Published var latestHeartRate: Double?

    
    /// Starts live heart rate updates using an anchored object query.
    func startLiveUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available.")
            return
        }
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type is not available.")
            return
        }
        
        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: nil,
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
    }
    
    /// Processes the received heart rate samples and sends them to the iPhone.
    private func processSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        for sample in samples {
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("❤️ Live Heart Rate: \(Int(heartRate)) BPM")
            self.latestHeartRate = heartRate
            DataSender.shared.sendHeartRateData(heartRate: heartRate)
        }
    }

}
