import SwiftUI

@main
struct HRVWatch_Watch_AppApp: App {
    @StateObject private var mockDataSender = MockDataSender.shared
    
    // Global setting: use mock or live data.
    private let useMockData: Bool = true  // Set to false for live data.
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockDataSender)
                .onAppear {
                    // Update the mock sender’s simulation flag.
                    mockDataSender.shouldSimulate = useMockData
                    if !useMockData {
                        // If live mode, ensure the mock timer isn’t running.
                        mockDataSender.stopStreamingHeartRate()
                    }
                }
        }
    }
}
