import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthKitManager = HealthKitManager() // used for live data
    @EnvironmentObject var mockDataSender: MockDataSender
    @State private var heartRate: Double?
    @State private var errorMessage: String?
    @State private var lastUpdate: Date?
    @State private var currentTime = Date()
    @State private var isWorkoutRunning: Bool = false
    
    // Display data based on the simulation flag from MockDataSender.
    private var displayedHeartRate: String {
        if mockDataSender.shouldSimulate {
            return mockDataSender.currentHeartRate.map { "\(Int($0)) BPM" } ?? "-"
        } else {
            if let lastUpdate = lastUpdate, currentTime.timeIntervalSince(lastUpdate) < 10, let rate = heartRate {
                return "\(Int(rate)) BPM"
            } else {
                return "Waiting..."
            }
        }
    }

    
    var body: some View {
            VStack {
                Text("Heart Rate")
                    .font(.headline)
                    .padding()
                
                Text(displayedHeartRate)
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .padding()
                
                Text(isWorkoutRunning ? "🏃‍♂️ Workout Active" : "⏹ Workout Stopped")
                    .font(.subheadline)
                    .foregroundColor(isWorkoutRunning ? .green : .gray)
                
                // Show Events Button
                Button(action: { mockDataSender.showEventList = true }) {
                    Text("Events (\(mockDataSender.events.count))")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .onAppear {
                if mockDataSender.shouldSimulate {
                    mockDataSender.startStreamingHeartRate()
                } else {
                    mockDataSender.stopStreamingHeartRate()
                    
                    healthKitManager.requestAuthorization { success, error in
                        if success {
                            healthKitManager.startLiveHeartRateUpdates { rate, error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        self.errorMessage = "Failed to get live updates: \(error.localizedDescription)"
                                    } else if let rate = rate {
                                        self.heartRate = rate
                                        self.lastUpdate = Date()
                                        self.mockDataSender.sendHeartRateData(heartRate: rate)
                                    } else {
                                        self.errorMessage = "No heart rate data available."
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.errorMessage = "Authorization failed: \(error?.localizedDescription ?? "Unknown reason")"
                            }
                        }
                    }
                }
            }
        }
    
    private func requestAuthorizationAndStartWorkout() {
            healthKitManager.requestAuthorization { success, error in
                if success {
                    startLiveUpdates()
                    healthKitManager.startWorkoutSession()
                    DispatchQueue.main.async {
                        self.isWorkoutRunning = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = error?.localizedDescription ?? "Authorization not granted."
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
                        self.lastUpdate = Date()
                        self.mockDataSender.sendHeartRateData(heartRate: rate)
                    } else {
                        self.errorMessage = "No heart rate data available."
                    }
                }
            }
        }
}
