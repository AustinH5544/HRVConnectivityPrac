import WatchConnectivity
import SwiftUI

class MockDataSender: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = MockDataSender()
    
    @Published var currentHeartRate: Double?
    @Published var events: [Event] = []
    @Published var showEventList: Bool = false
    
    // This property controls whether mock simulation should run.
    @Published var shouldSimulate: Bool = true
    
    private var heartRateTimer: Timer?
    private var baseHeartRate: Double = 75.0
    private var isIncreasing = true
    private let threshold: Double = 85.0
    
    private var activeEvent: Event?
    
    private override init() {
        super.init()
        activateSession()
        // Do not call startStreamingHeartRate() here;
        // let the ContentView/App decide when to start simulation.
    }
    
    private func activateSession() {
        guard WCSession.isSupported() else {
            print("WCSession is not supported on this device")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func startStreamingHeartRate() {
        // Only start if simulation is enabled.
        guard shouldSimulate else { return }
        // Avoid creating multiple timers.
        if heartRateTimer != nil { return }
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.generateAndSendHeartRate()
        }
    }
    
    func stopStreamingHeartRate() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
    }
    
    private func generateAndSendHeartRate() {
        // If simulation has been disabled mid-run, do nothing.
        guard shouldSimulate else { return }
        
        let variability = Double.random(in: -3...3)
        if isIncreasing {
            baseHeartRate += 1.0 + variability
            if baseHeartRate > 90 { isIncreasing = false }
        } else {
            baseHeartRate -= 1.0 + variability
            if baseHeartRate < 60 { isIncreasing = true }
        }
        
        let realisticHeartRate = max(60, min(90, baseHeartRate))
        currentHeartRate = realisticHeartRate
        
        if realisticHeartRate > threshold {
            if activeEvent == nil {
                startEvent()
            }
        } else {
            endEventIfNeeded()
        }
        
        sendHeartRateData(heartRate: realisticHeartRate)
    }
    
    private func startEvent() {
        if activeEvent != nil { return } // Prevent duplicate events.
        let eventID = UUID()
        let newEvent = Event(id: eventID, startTime: Date(), endTime: Date(), isConfirmed: nil)
        activeEvent = newEvent
        print("New event started: \(newEvent.id)")
    }
    
    private func endEventIfNeeded() {
        guard let event = activeEvent else { return }
        activeEvent = nil
        let endedEvent = Event(id: event.id, startTime: event.startTime, endTime: Date(), isConfirmed: nil)
        events.append(endedEvent)
        sendEventEndData(event: endedEvent)
        print("Event ended: \(endedEvent.id)")
    }
    
    private func sendEventEndData(event: Event) {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable")
            return
        }
        let isoDateFormatter = ISO8601DateFormatter()
        let eventData: [String: Any] = [
            "Event": "EventEnded",
            "EventID": event.id.uuidString,
            "StartTime": isoDateFormatter.string(from: event.startTime),
            "EndTime": isoDateFormatter.string(from: event.endTime)
        ]
        WCSession.default.sendMessage(eventData, replyHandler: nil) { error in
            print("Failed to send event end data: \(error.localizedDescription)")
        }
        print("Sent event: \(event.id)")
    }
    
    func handleUserResponse(event: Event, isConfirmed: Bool) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index].isConfirmed = isConfirmed
        events.remove(at: index)
        
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable")
            return
        }
        
        let response: [String: Any] = [
            "Event": "EventHandled",
            "EventID": event.id.uuidString,
            "IsConfirmed": isConfirmed
        ]
        
        WCSession.default.sendMessage(response, replyHandler: nil) { error in
            print("Failed to send EventHandled message: \(error.localizedDescription)")
        }
        print("Sent event confirmation for \(event.id)")
    }
    
    private func sendHeartRateData(heartRate: Double) {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable")
            return
        }
        
        let data: [String: Any] = [
            "HeartRate": heartRate,
            "Timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("Failed to send heart rate data: \(error.localizedDescription)")
        }
        
        print("Sent heart rate: \(heartRate) BPM")
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            // Check for a mode change message.
            if let mode = message["isMockMode"] as? Bool {
                // Update the mock simulation flag.
                self.shouldSimulate = mode
                if mode {
                    self.startStreamingHeartRate()
                    print("Switched to Mock Mode")
                } else {
                    self.stopStreamingHeartRate()
                    print("Switched to Live Mode")
                }
            }
            
            // Existing handling for events...
            if let event = message["Event"] as? String, event == "EventHandled",
               let eventID = message["EventID"] as? String, let uuid = UUID(uuidString: eventID) {
                self.events.removeAll { $0.id == uuid }
                print("Event \(uuid) removed from watch")
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch WCSession activation error: \(error.localizedDescription)")
        } else {
            print("Watch WCSession activated")
        }
    }
}
