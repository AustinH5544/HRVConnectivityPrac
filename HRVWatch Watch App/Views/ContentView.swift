import SwiftUI
import HealthKit

struct ContentView: View {
    // HealthKitManager handles authorization and workout session.
    private let healthKitManager = HealthKitManager()
    
    // Use the new LiveHeartRateManager to receive live heart rate data.
    @ObservedObject var liveHeartRateManager = LiveHeartRateManager.shared
    
    // Use the mock generator when in mock mode.
    @EnvironmentObject var mockHeartRateGenerator: MockHeartRateGenerator
    
    // DataModeManager (a shared singleton) controls the mode.
    @ObservedObject var dataModeManager = DataModeManager.shared
    
    @State private var errorMessage: String?
    @State private var isWorkoutRunning: Bool = false

    // Display heart rate from the appropriate source.
    private var displayedHeartRate: String {
        if dataModeManager.isMockMode {
            return mockHeartRateGenerator.currentHeartRate.map { "\(Int($0)) BPM" } ?? "-"
        } else {
            if let rate = liveHeartRateManager.latestHeartRate {
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
            
            // Show events button.
            Button(action: {
                // Toggle display of events; you might present a sheet here.
                mockHeartRateGenerator.showEventList.toggle()
            }) {
                Text("Events (\(mockHeartRateGenerator.events.count))")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            if dataModeManager.isMockMode {
                mockHeartRateGenerator.startStreamingHeartRate()
            } else {
                mockHeartRateGenerator.stopStreamingHeartRate()
                // Request HealthKit authorization and start live updates...
            }
        }
    }
}
