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
        let newProvider: HeartRateProvider = useMockData ? MockHeartRateGenerator() : LiveHeartRateManager()
        DataSender.shared.setProvider(newProvider)
        print("🔄 Mode set to \(useMockData ? "Mock" : "Live")")
    }

    /// Updates mode from an external source (like WatchConnectivity)
    func setMode(isMockMode: Bool) {
        if useMockData != isMockMode {  // Only update if there's a change
            useMockData = isMockMode
        }
    }
}
