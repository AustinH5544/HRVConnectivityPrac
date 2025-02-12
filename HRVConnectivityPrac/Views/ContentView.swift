import SwiftUI

struct ContentView: View {
    @ObservedObject private var connectivityManager = PhoneConnectivityManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("HRV Connectivity App")
                .font(.largeTitle)
                .padding()

            // Display heart rate received from the Watch
            Text("Heart Rate: \(connectivityManager.latestHeartRate.map { "\(Int($0)) BPM" } ?? "Waiting...")")
                .font(.title)
                .padding()

            Spacer()
        }
        .onAppear {
            print("📡 Listening for heart rate data from Watch")
        }
    }
}
