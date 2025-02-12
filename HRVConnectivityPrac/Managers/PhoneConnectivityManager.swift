import WatchConnectivity
import Foundation

class PhoneConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var latestHeartRate: Double?
    @Published var events: [Event] = []

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
        print("📡 iPhone WCSession Activated")
    }

    // MARK: - Receiving Data from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            print("📲 Received message from Watch: \(message)")

            if let heartRate = message["HeartRate"] as? Double {
                self.latestHeartRate = heartRate
                print("❤️ Updated heart rate: \(heartRate) BPM")
            }
        }
    }

    // MARK: - WCSession Lifecycle
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ iPhone WCSession activation error: \(error.localizedDescription)")
        } else {
            print("📡 iPhone WCSession Activated Successfully")
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
