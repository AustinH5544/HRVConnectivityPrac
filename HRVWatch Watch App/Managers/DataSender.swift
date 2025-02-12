//
//  DataSender.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import WatchConnectivity
import SwiftUI

class DataSender: ObservableObject {
    static let shared = DataSender()
    
    // MARK: - Data Sending Methods
    
    func sendHeartRateData(heartRate: Double) {
        guard WCSession.default.isReachable else {
            print("📡 ❌ iPhone is not reachable. Cannot send heart rate data.")
            return
        }
        let data: [String: Any] = [
            "HeartRate": heartRate,
            "Timestamp": Date().timeIntervalSince1970
        ]
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("📡 ❌ Failed to send heart rate data: \(error.localizedDescription)")
        }
        print("📡 ✅ Sent heart rate: \(heartRate) BPM to iPhone")
    }
    
    func sendEventEndData(event: Event) {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable")
            return
        }
        let isoFormatter = ISO8601DateFormatter()
        let eventData: [String: Any] = [
            "Event": "EventEnded",
            "EventID": event.id.uuidString,
            "StartTime": isoFormatter.string(from: event.startTime),
            "EndTime": isoFormatter.string(from: event.endTime)
        ]
        WCSession.default.sendMessage(eventData, replyHandler: nil) { error in
            print("Failed to send event end data: \(error.localizedDescription)")
        }
        print("Sent event: \(event.id)")
    }
    
    func sendModeChange(isMockMode: Bool) {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable for mode change")
            return
        }
        let data: [String: Any] = ["isMockMode": isMockMode]
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("Failed to send mode change: \(error.localizedDescription)")
        }
        print("Sent mode change: \(isMockMode ? "Mock" : "Live")")
    }
    func sendUserResponse(event: Event, isConfirmed: Bool) {
        guard WCSession.default.isReachable else {                print("iPhone is not reachable")
            return
        }
            
        let response: [String: Any] = [
            "Event": "EventHandled",
            "EventID": event.id.uuidString,
            "IsConfirmed": isConfirmed
        ]
            
        WCSession.default.sendMessage(response, replyHandler: nil) { error in
            print("Failed to send EventHandled message: \(error.localizedDescription)")
        }
        print("Sent event confirmation for \(event.id)")
    }
}

