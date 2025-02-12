//
//  EventListView.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import SwiftUI

struct EventListView: View {
    @ObservedObject var connectivityManager: PhoneConnectivityManager

    var body: some View {
        List {
            ForEach(connectivityManager.events) { event in
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
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Active Events")
    }
}
