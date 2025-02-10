import SwiftUI
import HealthKit

struct ContentView: View {
    // Use the workout-enabled HealthKitManager for live data
    private let healthKitManager = HealthKitManager()
    
    // We still use the mockDataSender to manage events and simulation.
    @EnvironmentObject var mockDataSender: MockDataSender
    
    @State private var heartRate: Double?
    @State private var errorMessage: String?
    @State private var lastUpdate: Date?
    @State private var currentTime = Date()
    
    // Computed property that displays the heart rate if updated in the last 30 seconds,
    // otherwise shows a placeholder.
    private var displayedHeartRate: String {
        if mockDataSender.shouldSimulate {
            if let rate = mockDataSender.currentHeartRate {
                return "\(Int(rate)) BPM"
            } else {
                return "-"
            }
        } else {
            if let lastUpdate = lastUpdate, currentTime.timeIntervalSince(lastUpdate) < 30, let rate = heartRate {
                return "\(Int(rate)) BPM"
            } else {
                return "-"
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
            
            // Button to show events.
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
                // Use mock data simulation.
                mockDataSender.startStreamingHeartRate()
            } else {
                // For live data, ensure mock simulation is stopped,
                // then request authorization and start the workout.
                mockDataSender.stopStreamingHeartRate()
                requestAuthorizationAndStartWorkout()
            }
        }
        // Update currentTime every second so the UI refreshes appropriately.
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            self.currentTime = now
        }
        .sheet(isPresented: $mockDataSender.showEventList) {
            EventListView().environmentObject(mockDataSender)
        }
    }
    
    // This function requests HealthKit authorization and starts a workout session
    // to receive live heart rate updates.
    private func requestAuthorizationAndStartWorkout() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                DispatchQueue.main.async {
                    // Set the callback for heart rate updates from the workout.
                    healthKitManager.onHeartRateUpdate = { newRate in
                        DispatchQueue.main.async {
                            self.heartRate = newRate
                            self.lastUpdate = Date()
                        }
                    }
                    // Start the workout session, which puts the app in workout state.
                    healthKitManager.startWorkout()
                }
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
}
