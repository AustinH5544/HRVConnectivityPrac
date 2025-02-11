import WatchConnectivity

class DataSender: ObservableObject {
    private var heartRateProvider: HeartRateProvider
    static let shared = DataSender(heartRateProvider: MockHeartRateGenerator()) // Default to mock

    @Published var currentHeartRate: Double?
    
    private init(heartRateProvider: HeartRateProvider) {
        self.heartRateProvider = heartRateProvider
    }

    func setProvider(_ provider: HeartRateProvider) {
        self.heartRateProvider = provider
    }

    func startSendingData() {
        heartRateProvider.startMonitoring()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.sendHeartRateData()
        }
    }

    func stopSendingData() {
        heartRateProvider.stopMonitoring()
    }

    /// Sends heart rate data from the provider to the iPhone via WatchConnectivity.
    private func sendHeartRateData() {
        guard let heartRate = heartRateProvider.currentHeartRate else { return }
        
        guard WCSession.default.isReachable else {
            print("📡 ❌ iPhone not reachable. Cannot send data.")
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
}
