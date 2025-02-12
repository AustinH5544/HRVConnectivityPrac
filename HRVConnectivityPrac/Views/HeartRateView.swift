import SwiftUI

struct ContentView: View {
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("HRV Connectivity App")
                    .font(.largeTitle)
                    .padding()

                if let heartRate = connectivityManager.latestHeartRate {
                    Text("Heart Rate: \(Int(heartRate)) BPM")
                        .font(.title)
                        .padding()
                } else {
                    Text("Waiting for heart rate data...")
                        .font(.title2)
                        .padding()
                }

                if let rmssd = connectivityManager.hrvCalculator.rmssd,
                   let sdnn = connectivityManager.hrvCalculator.sdnn,
                   let pnn50 = connectivityManager.hrvCalculator.pnn50 {
                    VStack(spacing: 5) {
                        Text("RMSSD: \(String(format: "%.1f", rmssd)) ms")
                        Text("SDNN: \(String(format: "%.1f", sdnn)) ms")
                        Text("PNN50: \(String(format: "%.1f", pnn50))%")
                    }
                    .font(.headline)
                    .padding()
                } else {
                    Text("Calculating HRV statistics...")
                        .font(.headline)
                }

                if connectivityManager.events.isEmpty {
                    Text("No active events")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    NavigationLink(
                        destination: EventListView()
                    ) {
                        Text("View Active Events (\(connectivityManager.events.count))")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Home", displayMode: .inline)
        }
    }
}
