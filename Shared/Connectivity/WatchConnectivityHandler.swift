import WatchConnectivity
import Foundation

class WatchConnectivityHandler: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityHandler()

    private override init() {
        super.init()
        activateSession()
    }

    /// Activates the WCSession for communication
    private func activateSession() {
        guard WCSession.isSupported() else {
            print("❌ WCSession is NOT supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        print("📡 WCSession State: \(session.activationState.rawValue)")
    }

    // MARK: - Receiving Messages from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            print("📲 🔍 Received message: \(message)")

            // Handle Mode Switching (Mock vs Live)
            if let isMockMode = message["isMockMode"] as? Bool {
                DataModeManager.shared.setMode(isMockMode: isMockMode)
                print("📡 Mode Updated: \(isMockMode ? "Mock Mode" : "Live Mode")")
            }

            // Handle Event Removal
            if let eventAction = message["Event"] as? String, eventAction == "EventHandled",
               let eventID = message["EventID"] as? String,
               let uuid = UUID(uuidString: eventID) {
                print("🗑 Event \(uuid) removed from watch")
            }
        }
    }

    // MARK: - Sending Messages to iPhone
    func sendHeartRateData(heartRate: Double) {
        guard WCSession.default.isReachable else {
            print("📡 ❌ iPhone is not reachable. Cannot send heart rate data.")
            return
        }

        let data: [String: Any] = [
            "HeartRate": heartRate,
            "Timestamp": Date().timeIntervalSince1970
        ]

        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("📡 ❌ Failed to send heart rate: \(error.localizedDescription)")
        }
        print("📡 ✅ Sent heart rate: \(heartRate) BPM to iPhone")
    }

    func sendEventEndData(event: Event) {
        guard WCSession.default.isReachable else {
            print("📡 ❌ iPhone is not reachable. Cannot send event data.")
            return
        }

        let isoFormatter = ISO8601DateFormatter()
        let eventData: [String: Any] = [
            "Event": "EventEnded",
            "EventID": event.id.uuidString,
            "StartTime": isoFormatter.string(from: event.startTime),
            "EndTime": isoFormatter.string(from: event.endTime)
        ]

        WCSession.default.sendMessage(eventData, replyHandler: nil) { error in
            print("📡 ❌ Failed to send event end data: \(error.localizedDescription)")
        }
        print("📡 ✅ Sent event end data for \(event.id)")
    }

    // MARK: - WCSession Lifecycle Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation error: \(error.localizedDescription)")
        } else {
            print("📡 WCSession activated successfully.")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession deactivated. Reactivating...")
        WCSession.default.activate()
    }
}


