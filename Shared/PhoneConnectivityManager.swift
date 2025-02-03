//
//  PhoneConnectivityManager.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/3/25.
//

import WatchConnectivity
import SwiftUI

class PhoneConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var events: [Event] = [] //List of events
    @Published var latestHeartRate: Double? = nil
    @Published var isPromptVisible: Bool = false {
        didSet {
            print("isPromptVisible updated: \(isPromptVisible)")
        }
    }
    @Published var eventStartTime: Date? = nil
    @Published var eventEndTime: Date? = nil
    @Published var eventMessage: String? = nil

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate Methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("iPhone WCSession activation error: \(error.localizedDescription)")
        } else {
            print("iPhone WCSession activated with state: \(activationState.rawValue)")
        }
    }


    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            // Handles heart rate data
            if let heartRate = message["HeartRate"] as? Double {
                self.latestHeartRate = heartRate
                print("Received heart rate from Watch: \(heartRate) BPM")
            }
            
            //Handles event syncing
            if let event = message["Event"] as? String, event == "EventEnded" {
                let isoDateFormatter = ISO8601DateFormatter()

                if let eventIDString = message["EventID"] as? String,
                   let eventID = UUID(uuidString: eventIDString),  // Uses the same ID from the Watch
                   let startTimeString = message["StartTime"] as? String,
                   let endTimeString = message["EndTime"] as? String,
                   let startTime = isoDateFormatter.date(from: startTimeString),
                   let endTime = isoDateFormatter.date(from: endTimeString) {

                    let newEvent = Event(id: eventID, startTime: startTime, endTime: endTime, isConfirmed: nil)

                    // Ensure we don't duplicate events
                    if !self.events.contains(where: { $0.id == eventID }) {
                        self.events.append(newEvent)
                        print("New event received on iPhone: \(newEvent.id)")
                    }
                }
            }

            if let event = message["Event"] as? String, event == "EventHandled" {
                if let eventIDString = message["EventID"] as? String,
                   let uuid = UUID(uuidString: eventIDString) {
                    
                    self.events.removeAll { $0.id == uuid }
                    print("Event \(uuid) removed from iPhone")
                }
            }
        }
    }

    
    func sendUserResponse(event: Event, isConfirmed: Bool) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }

        let response: [String: Any] = [
            "Event": "EventHandled",
            "EventID": event.id.uuidString,
            "IsConfirmed": isConfirmed
        ]

        WCSession.default.sendMessage(response, replyHandler: nil) { error in
            print("Failed to send user response to watch: \(error.localizedDescription)")
        }

        // Update and remove the event
        DispatchQueue.main.async {
            if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                self.events.remove(at: index) // Remove the event
                print("Event \(event.id) \(isConfirmed ? "confirmed" : "dismissed") and removed.")
            }
        }
    }


    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        WCSession.default.activate()
    }
    
    func sendUserResponse(isConfirmed: Bool) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }

        let response: [String: Any] = [
            "Event": "EventHandled",
            "IsConfirmed": isConfirmed
        ]

        WCSession.default.sendMessage(response, replyHandler: nil) { error in
            print("Failed to send user response: \(error.localizedDescription)")
        }

        // Hide the prompt after response
        self.isPromptVisible = false

        if isConfirmed {
            print("Event confirmed: Start - \(eventStartTime!), End - \(eventEndTime!)")
        } else {
            print("Event dismissed.")
        }
    }
}
