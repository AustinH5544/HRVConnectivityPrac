import SwiftUI
// (Remove SwiftData if not using it throughout your project.)

struct ContentView: View {
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared
    @State private var isMockMode: Bool = true  // local state for toggling the mode

    var body: some View {
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
            
            // Mode Toggle Button
            Button(action: {
                isMockMode.toggle()
                connectivityManager.sendModeChange(isMockMode: isMockMode)
            }) {
                Text(isMockMode ? "Switch to Live Mode" : "Switch to Mock Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(isMockMode ? Color.blue : Color.green)
                    .cornerRadius(8)
            }
            
            if connectivityManager.events.isEmpty {
                Text("No active events")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(connectivityManager.events) { event in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Event ID: \(event.id.uuidString.prefix(8))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Start: \(event.startTime.formatted())")
                                .font(.subheadline)
                            Text("End: \(event.endTime.formatted())")
                                .font(.subheadline)
                            HStack {
                                Button("Confirm") {
                                    connectivityManager.sendUserResponse(event: event, isConfirmed: true)
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                
                                Button("Dismiss") {
                                    connectivityManager.sendUserResponse(event: event, isConfirmed: false)
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .listStyle(PlainListStyle())
            }
            Spacer()
        }
        .padding()
    }
}
