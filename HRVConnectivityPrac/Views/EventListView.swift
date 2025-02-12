//
//  EventListView.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import SwiftUI

struct EventListView: View {
    @ObservedObject var eventDetector = EventDetectionManager.shared

    var body: some View {
        NavigationView {
            List {
                ForEach(eventDetector.events) { event in
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
