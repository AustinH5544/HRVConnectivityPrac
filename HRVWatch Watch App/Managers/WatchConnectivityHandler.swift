import WatchConnectivity
import Foundation

class WatchConnectivityHandler: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityHandler()

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else {
            print("❌ WCSession is NOT supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        print("📡 Watch WCSession Activated")
    }

    // ✅ Send heart rate from Watch to Phone
    func sendHeartRateData(heartRate: Double) {
        guard WCSession.default.isReachable else {
            print("📡 ❌ Phone is not reachable. Cannot send heart rate data.")
            return
        }

        let data: [String: Any] = [
            "HeartRate": heartRate,
            "Timestamp": Date().timeIntervalSince1970
        ]

        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("📡 ❌ Failed to send heart rate data: \(error.localizedDescription)")
        }
        print("📡 ✅ Sent heart rate: \(heartRate) BPM to Phone")
    }

    // ✅ Handle Activation State
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch WCSession activation error: \(error.localizedDescription)")
        } else {
            print("📡 Watch WCSession activated successfully.")
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive if needed
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session if necessary
        session.activate()
    }
    #endif
}
