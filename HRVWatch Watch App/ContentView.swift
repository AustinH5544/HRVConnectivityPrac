import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthKitManager = HealthKitManager() // used for live data
    @EnvironmentObject var mockDataSender: MockDataSender
    @State private var heartRate: Double?
    @State private var errorMessage: String?
    @State private var lastUpdate: Date?

    
    // Display data based on the simulation flag from MockDataSender.
    private var displayedHeartRate: String {
        if mockDataSender.shouldSimulate {
            if let rate = mockDataSender.currentHeartRate {
                return "\(Int(rate)) BPM"
            } else {
                return "-"
            }
        } else {
            // For live data, if no update was received in the last 30 seconds, show a placeholder.
            if let lastUpdate = lastUpdate, Date().timeIntervalSince(lastUpdate) < 30, let rate = heartRate {
                return "\(Int(rate)) BPM"
            } else {
                return "No live data"
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
                mockDataSender.startStreamingHeartRate()
            } else {
                mockDataSender.stopStreamingHeartRate()
                requestAuthorization()
            }
        }
        .sheet(isPresented: $mockDataSender.showEventList) {
            EventListView()
                .environmentObject(mockDataSender)
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
                    self.lastUpdate = Date()
                    self.mockDataSender.sendHeartRateData(heartRate: rate)
                } else {
                    self.errorMessage = "No heart rate data available."
                }
            }
        }
    }
}
