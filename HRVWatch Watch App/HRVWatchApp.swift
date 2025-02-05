import SwiftUI

@main
struct HRVWatch_Watch_AppApp: App {
    @StateObject private var mockDataSender = MockDataSender.shared
    
    // Global default: change this to false for live mode.
    private let useMockData: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockDataSender)
                .onAppear {
                    mockDataSender.shouldSimulate = useMockData
                    if !useMockData {
                        mockDataSender.stopStreamingHeartRate()
                    }
                }
        }
    }
}
