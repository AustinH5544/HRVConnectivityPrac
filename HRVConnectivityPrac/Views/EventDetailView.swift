//
//  EventDetailView.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event

    var body: some View {
        VStack(spacing: 20) {
            Text("Event Details")
                .font(.headline)
            Text("ID: \(event.id.uuidString)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("Start: \(event.startTime.formatted())")
            Text("End: \(event.endTime.formatted())")
            
            HStack(spacing: 20) {
                Button("Confirm") {
                    PhoneConnectivityManager.shared.sendUserResponse(event: event, isConfirmed: true)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Dismiss") {
                    PhoneConnectivityManager.shared.sendUserResponse(event: event, isConfirmed: false)
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Event", displayMode: .inline)
    }
}
