import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthKitManager = HealthKitManager() // Used for live data
    @ObservedObject private var mockHeartRateGenerator = MockHeartRateGenerator() // Mock data generator
    @ObservedObject private var dataModeManager = DataModeManager.shared

    @State private var heartRate: Double?
    @State private var errorMessage: String?
    @State private var lastUpdate: Date?
    @State private var isWorkoutRunning: Bool = false

    private var displayedHeartRate: String {
        if let rate = heartRate {
            return "\(Int(rate)) BPM"
        } else {
            return "Waiting..."
        }
    }

    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding()

            Text(displayedHeartRate)
                .font(.title3)
                .foregroundColor(.red)
                .padding()

            Text(isWorkoutRunning ? "🏃‍♂️ Workout Active" : "⏹ Workout Stopped")
                .font(.caption)
                .foregroundColor(isWorkoutRunning ? .green : .gray)

            Spacer()
        }
        .onAppear {
            if dataModeManager.useMockData {
                print("🛠 Mock Mode Active")
                startMockHeartRateUpdates()
            } else {
                print("📡 Live Mode Active (HealthKit)")
                startLiveHeartRateUpdates()
            }
        }
        .onReceive(mockHeartRateGenerator.$currentHeartRate) { newHeartRate in
            if dataModeManager.useMockData {
                DispatchQueue.main.async {
                    print("🛠 Updating Mock Heart Rate: \(newHeartRate ?? 0)")
                    self.heartRate = newHeartRate
                    WatchConnectivityHandler.shared.sendHeartRateData(heartRate: newHeartRate ?? 0) // ✅ Send mock data
                }
            }
        }
    }

    // MARK: - Start Mock Heart Rate Updates
    private func startMockHeartRateUpdates() {
        print("🛠 Starting Mock Heart Rate Generator...")
        mockHeartRateGenerator.startMonitoring()
    }

    // MARK: - Start Live Heart Rate Updates
    private func startLiveHeartRateUpdates() {
        print("📡 Requesting HealthKit Authorization...")
        healthKitManager.requestAuthorization { success, error in
            if success {
                print("📡 HealthKit Authorization Granted")
                healthKitManager.startLiveHeartRateUpdates { rate, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Error in HealthKit Updates: \(error.localizedDescription)")
                            self.errorMessage = "Failed: \(error.localizedDescription)"
                        } else if let rate = rate {
                            print("❤️ Live Heart Rate Received: \(Int(rate)) BPM")
                            self.heartRate = rate
                            self.lastUpdate = Date()
                            WatchConnectivityHandler.shared.sendHeartRateData(heartRate: rate) // ✅ Send live data
                        } else {
                            print("❌ No Heart Rate Data Available")
                            self.errorMessage = "No heart rate data."
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("❌ HealthKit Authorization Failed")
                    self.errorMessage = "Authorization failed"
                }
            }
        }
    }
}
