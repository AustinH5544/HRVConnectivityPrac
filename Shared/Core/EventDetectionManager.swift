//
//  EventDetectionManager.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import Foundation
import Combine

class EventDetectionManager: ObservableObject {
    static let shared = EventDetectionManager()
    
    @Published var activeEvent: Event?
    @Published var events: [Event] = []
    
    // The RMSSD threshold to trigger events.
    let rmssdThreshold: Double = 30.0
    
    /// Call this function with your HRVCalculator to evaluate whether an event should start or end.
    func evaluateHRV(_ hrvCalculator: HRVCalculator) {
        if let currentRMSSD = hrvCalculator.rmssd {
            if currentRMSSD < rmssdThreshold, activeEvent == nil {
                startEvent()
            } else if currentRMSSD >= rmssdThreshold, let event = activeEvent {
                endEvent(event: event)
            }
        }
    }
    
    private func startEvent() {
        let newEvent = Event(id: UUID(), startTime: Date(), endTime: Date(), isConfirmed: nil)
        activeEvent = newEvent
        print("New event started: \(newEvent.id)")
        // Optionally, you could also send an "event started" message here.
    }
    
    private func endEvent(event: Event) {
        guard let active = activeEvent, active.id == event.id else { return }
        var endedEvent = active
        endedEvent.endTime = Date()
        events.append(endedEvent)
        activeEvent = nil
        print("Event ended: \(endedEvent.id)")
        // Notify via DataSender that an event ended.
        DataSender.shared.sendEventEndData(event: endedEvent)
    }
    
    /// Called when a connectivity message indicates the event was handled.
    func handleEventHandled(eventID: UUID) {
        events.removeAll { $0.id == eventID }
        if let active = activeEvent, active.id == eventID {
            activeEvent = nil
        }
        print("Handled event \(eventID)")
    }
}
