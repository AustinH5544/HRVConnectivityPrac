import SwiftUI

struct EventListView: View {
    @EnvironmentObject var mockDataSender: MockDataSender

    var body: some View {
        NavigationView {
            List {
                ForEach(mockDataSender.events) { event in
                    VStack(alignment: .leading) {
                        Text("Event ID: \(event.id.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Start: \(event.startTime.formatted())")
                            .font(.subheadline)
                        Text("End: \(event.endTime.formatted())")
                            .font(.subheadline)
                        HStack {
                            Button("Confirm") {
                                mockDataSender.handleUserResponse(event: event, isConfirmed: true)
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button("Dismiss") {
                                mockDataSender.handleUserResponse(event: event, isConfirmed: false)
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Active Events")
        }
    }
}
