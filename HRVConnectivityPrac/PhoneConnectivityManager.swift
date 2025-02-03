import WatchConnectivity
import SwiftUI

class PhoneConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var events: [Event] = []
    @Published var latestHeartRate: Double? = nil
    @Published var isPromptVisible: Bool = false {
        didSet {
            print("isPromptVisible updated: \(isPromptVisible)")
        }
    }
    @Published var eventStartTime: Date? = nil
    @Published var eventEndTime: Date? = nil
    @Published var eventMessage: String? = nil

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate Methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("iPhone WCSession activation error: \(error.localizedDescription)")
        } else {
            print("iPhone WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["HeartRate"] as? Double {
                self.latestHeartRate = heartRate
                print("Received heart rate from Watch: \(heartRate) BPM")
            }
            
            if let eventAction = message["Event"] as? String {
                switch eventAction {
                case "EventEnded":
                    let isoFormatter = ISO8601DateFormatter()
                    if let eventIDString = message["EventID"] as? String,
                       let eventID = UUID(uuidString: eventIDString),
                       let startTimeStr = message["StartTime"] as? String,
                       let endTimeStr = message["EndTime"] as? String,
                       let startTime = isoFormatter.date(from: startTimeStr),
                       let endTime = isoFormatter.date(from: endTimeStr) {
                        
                        let newEvent = Event(id: eventID, startTime: startTime, endTime: endTime, isConfirmed: nil)
                        if !self.events.contains(where: { $0.id == eventID }) {
                            self.events.append(newEvent)
                            print("New event received on iPhone: \(newEvent.id)")
                        }
                    }
                case "EventHandled":
                    if let eventIDString = message["EventID"] as? String,
                       let uuid = UUID(uuidString: eventIDString) {
                        self.events.removeAll { $0.id == uuid }
                        print("Event \(uuid) removed from iPhone")
                    }
                default:
                    break
                }
            }
        }
    }
    
    func sendUserResponse(event: Event, isConfirmed: Bool) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }

        let response: [String: Any] = [
            "Event": "EventHandled",
            "EventID": event.id.uuidString,
            "IsConfirmed": isConfirmed
        ]

        WCSession.default.sendMessage(response, replyHandler: nil) { error in
            print("Failed to send user response to watch: \(error.localizedDescription)")
        }

        DispatchQueue.main.async {
            self.events.removeAll { $0.id == event.id }
            print("Event \(event.id) \(isConfirmed ? "confirmed" : "dismissed") and removed.")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        WCSession.default.activate()
    }
    
    func sendModeChange(isMockMode: Bool) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let modeMessage: [String: Any] = ["isMockMode": isMockMode]
        WCSession.default.sendMessage(modeMessage, replyHandler: nil) { error in
            print("Failed to send mode change: \(error.localizedDescription)")
        }
        print("Sent mode change: \(isMockMode ? "Mock" : "Live")")
    }
}
