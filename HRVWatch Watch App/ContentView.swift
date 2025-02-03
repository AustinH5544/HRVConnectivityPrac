import SwiftUI
import HealthKit

struct ContentView: View {
    private let healthKitManager = HealthKitManager() // for live data
    @EnvironmentObject var mockDataSender: MockDataSender
    @State private var heartRate: Double?
    @State private var errorMessage: String?
    
    // Toggle this flag to choose between mock and live data:
    private let useMockData: Bool = false  // Set to false to use live heart rate data.
    
    // Pick the data source based on the flag.
    private var displayedHeartRate: Double? {
        mockDataSender.shouldSimulate ? mockDataSender.currentHeartRate : heartRate
    }
    
    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.headline)
                .padding()
            
            if let currentRate = displayedHeartRate {
                Text("\(Int(currentRate)) BPM")
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
            
            // Button to navigate to event list.
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
            if useMockData {
                // In mock mode, ensure the simulation is enabled and start the timer.
                mockDataSender.shouldSimulate = true
                mockDataSender.startStreamingHeartRate()
            } else {
                // In live mode, turn off mock simulation and start live updates.
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
