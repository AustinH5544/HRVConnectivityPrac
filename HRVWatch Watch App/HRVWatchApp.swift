import SwiftUI

@main
struct HRVWatch_Watch_AppApp: App {
    @StateObject private var mockHeartRateGenerator = MockHeartRateGenerator.shared
    
    // Global default: change this to false for live mode.
    private let useMockData: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockHeartRateGenerator)
                .onAppear {
                    // Set the global mode
                    DataModeManager.shared.isMockMode = useMockData
                    
                    // Optionally, ensure simulation is stopped in live mode.
                    if !useMockData {
                        mockHeartRateGenerator.stopStreamingHeartRate()
                    }
                }
        }
    }
}
