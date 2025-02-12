import Foundation
import Combine

class DataModeManager: ObservableObject {
    static let shared = DataModeManager()

    @Published var useMockData: Bool = false {
        didSet {
            updateProvider()
        }
    }

    private init() {
        updateProvider()
    }

    /// Updates the `HeartRateProvider` based on the current mode
    private func updateProvider() {
        let newProvider: HeartRateProvider
        
        #if os(watchOS)
        newProvider = useMockData ? MockHeartRateGenerator() : LiveHeartRateManager()
        #else
        newProvider = PhoneConnectivityManager.shared as! any HeartRateProvider // Receives real data from the watch
        #endif
        
        DataSender.shared.setProvider(newProvider)
        print("🔄 Mode set to \(useMockData ? "Mock" : "Live")")
    }

    /// Updates mode from an external source (like WatchConnectivity)
    func setMode(isMockMode: Bool) {
        if useMockData != isMockMode {
            useMockData = isMockMode
        }
    }
}
