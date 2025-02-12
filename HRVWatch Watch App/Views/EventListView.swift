import SwiftUI

struct EventListView: View {
    @EnvironmentObject var mockHeartRateGenerator: MockHeartRateGenerator

    var body: some View {
        NavigationView {
            List {
                ForEach(mockHeartRateGenerator.events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        VStack(alignment: .leading) {
                            Text("Event ID: \(event.id.uuidString.prefix(8))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Start: \(event.startTime.formatted())")
                                .font(.subheadline)
                            Text("End: \(event.endTime.formatted())")
                                .font(.subheadline)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Active Events")
        }
    }
}
