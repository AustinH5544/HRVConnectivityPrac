import SwiftUI

struct EventListView: View {
    @EnvironmentObject var mockHeartRateGenerator: MockHeartRateGenerator

    var body: some View {
        NavigationView {
            List {
                ForEach(mockHeartRateGenerator.events) { event in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event ID: \(event.id.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Start: \(event.startTime.formatted())")
                            .font(.subheadline)
                        Text("End: \(event.endTime.formatted())")
                            .font(.subheadline)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                MockHeartRateGenerator.shared.handleUserResponse(event: event, isConfirmed: true)
                            }) {
                                Text("Confirm")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            
                            Button(action: {
                                MockHeartRateGenerator.shared.handleUserResponse(event: event, isConfirmed: false)
                            }) {
                                Text("Dismiss")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Active Events")
        }
    }
}
