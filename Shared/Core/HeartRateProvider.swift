protocol HeartRateProvider {
    func startMonitoring()   // Start collecting heart rate data
    func stopMonitoring()    // Stop collecting heart rate data
    var currentHeartRate: Double? { get }  // Latest heart rate reading
}

