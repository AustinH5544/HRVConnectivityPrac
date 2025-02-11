import Foundation
import Combine

class MockHeartRateGenerator: HeartRateProvider, ObservableObject {
    @Published var currentHeartRate: Double?

    private var heartRateTimer: Timer?
    private var baseHeartRate: Double = 75.0
    private var isIncreasing = true

    func startMonitoring() {
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.generateMockHeartRate()
        }
    }

    func stopMonitoring() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
    }

    private func generateMockHeartRate() {
        let variability = Double.random(in: -5...5)
        if isIncreasing {
            baseHeartRate += 1.0 + variability
            if baseHeartRate > 120 { isIncreasing = false }
        } else {
            baseHeartRate -= 1.0 + variability
            if baseHeartRate < 40 { isIncreasing = true }
        }

        currentHeartRate = max(40, min(120, baseHeartRate))
    }
}
