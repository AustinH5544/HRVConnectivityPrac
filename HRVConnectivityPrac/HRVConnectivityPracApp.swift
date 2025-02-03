import SwiftUI

@main
struct HRVMockTestApp: App {
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}
