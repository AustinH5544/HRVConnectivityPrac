//
//  EventDetailView.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event

    var body: some View {
        VStack(spacing: 12) {
            Text("Event Details")
                .font(.headline)
            Text("ID: \(event.id.uuidString)")
                .font(.caption)
            Text("Start: \(event.startTime.formatted())")
            Text("End: \(event.endTime.formatted())")
            
            HStack {
                Button("Confirm") {
                    // You can notify the shared event detector if needed:
                    DataSender.shared.sendUserResponse(event: event, isConfirmed: true)
                    EventDetectionManager.shared.handleEventHandled(eventID: event.id)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Dismiss") {
                    DataSender.shared.sendUserResponse(event: event, isConfirmed: false)
                    EventDetectionManager.shared.handleEventHandled(eventID: event.id)
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}
