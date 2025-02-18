import SwiftUI

@main
struct HRVWatch_Watch_AppApp: App {
    // Instantiate the connectivity handler on launch.
    init() {
        _ = WatchConnectivityHandler.shared
    }
    
    @StateObject private var mockHeartRateGenerator = MockHeartRateGenerator.shared
    @StateObject private var dataModeManager = DataModeManager.shared
    @StateObject private var eventDetectionManager = EventDetectionManager.shared
    
    // Global default: change this to false for live mode.
    private let useMockData: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockHeartRateGenerator)
                .environmentObject(dataModeManager)
                .environmentObject(eventDetectionManager)
        }
    }
}
