//
//  Event.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/3/25.
//

import Foundation

struct Event: Identifiable, Codable {
    let id: UUID // Unique identifier for the event
    let startTime: Date
    var endTime: Date
    var isConfirmed: Bool?
}
