//
//  MockHeartRateManager.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import WatchConnectivity
import SwiftUI

class MockHeartRateGenerator: ObservableObject {
    static let shared = MockHeartRateGenerator()
    
    @Published var currentHeartRate: Double?
    @Published var events: [Event] = []
    @Published var showEventList: Bool = false
    
    private var heartRateTimer: Timer?
    private var baseHeartRate: Double = 75.0
    private var isIncreasing = true
    
    private let hrvCalculator = HRVCalculator()
    private let rmssdThreshold: Double = 30.0 // Adjust threshold as needed
    
    private var activeEvent: Event?
    
    func startStreamingHeartRate() {
        guard heartRateTimer == nil else { return }
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.generateAndSendHeartRate()
        }
    }

    
    func stopStreamingHeartRate() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
    }
    
    private func generateAndSendHeartRate() {
        let variability = Double.random(in: -5...5)
        if isIncreasing {
            baseHeartRate += 1.0 + variability
            if baseHeartRate > 120 { isIncreasing = false }
        } else {
            baseHeartRate -= 1.0 + variability
            if baseHeartRate < 40 { isIncreasing = true }
        }
        
        let realisticHeartRate = max(40, min(120, baseHeartRate))
        currentHeartRate = realisticHeartRate
        
        hrvCalculator.addBeat(heartRate: realisticHeartRate, at: Date())
        
        print("Current RMSSD: \(hrvCalculator.rmssd ?? 0)")
        
        if let currentRMSSD = hrvCalculator.rmssd {
            if currentRMSSD < rmssdThreshold, activeEvent == nil {
                startEvent()
            } else if currentRMSSD >= rmssdThreshold, activeEvent != nil {
                endEventIfNeeded()
            }
        }
        
        DataSender.shared.sendHeartRateData(heartRate: realisticHeartRate)
    }
    
    private func startEvent() {
        guard activeEvent == nil else { return }
        let newEvent = Event(id: UUID(), startTime: Date(), endTime: Date(), isConfirmed: nil)
        activeEvent = newEvent
        print("New event started: \(newEvent.id)")
        // Optionally: send event start data if needed
    }
    
    private func endEventIfNeeded() {
        guard let event = activeEvent else { return }
        activeEvent = nil
        let endedEvent = Event(id: event.id, startTime: event.startTime, endTime: Date(), isConfirmed: nil)
        events.append(endedEvent)
        DataSender.shared.sendEventEndData(event: endedEvent)
        print("Event ended: \(endedEvent.id)")
    }
}

extension MockHeartRateGenerator {
    func handleUserResponse(event: Event, isConfirmed: Bool) {
        // Update the event in the local events array.
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isConfirmed = isConfirmed
            events.remove(at: index)
        }
        // Optionally, notify the paired device.
        DataSender.shared.sendUserResponse(event: event, isConfirmed: isConfirmed)
    }
}
