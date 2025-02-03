import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthKitManager = HealthKitManager()
    @State private var heartRate: Double?
    @State private var errorMessage: String?

    init() {
        healthKitManager.isMockMode = true // Enable mock mode for testing
    }

    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.headline)
                .padding()

            if let heartRate = heartRate {
                Text("\(Int(heartRate)) BPM")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Text("Waiting for heart rate...")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            requestAuthorization()
        }
    }

    private func requestAuthorization() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                startLiveUpdates()
            } else if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Authorization failed: \(error.localizedDescription)"
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Authorization not granted."
                }
            }
        }
    }

    private func startLiveUpdates() {
        healthKitManager.startLiveHeartRateUpdates { rate, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to get live updates: \(error.localizedDescription)"
                } else if let rate = rate {
                    self.heartRate = rate
                } else {
                    self.errorMessage = "No heart rate data available."
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
