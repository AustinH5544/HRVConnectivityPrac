import Foundation

class EventDetectionManager: ObservableObject {
    @Published var activeEvent: Event?
    @Published var events: [Event] = []
    
    private let hrvCalculator = HRVCalculator()
    private let rmssdThreshold: Double = 30.0

    func processHeartRate(heartRate: Double) {
        hrvCalculator.addBeat(heartRate: heartRate, at: Date())

        if let rmssd = hrvCalculator.rmssd {
            if rmssd < rmssdThreshold, activeEvent == nil {
                startEvent()
            } else if rmssd >= rmssdThreshold, activeEvent != nil {
                endEvent()
            }
        }
    }

    private func startEvent() {
        let event = Event(id: UUID(), startTime: Date(), endTime: Date(), isConfirmed: nil)
        activeEvent = event
    }

    private func endEvent() {
        guard let event = activeEvent else { return }
        events.append(Event(id: event.id, startTime: event.startTime, endTime: Date(), isConfirmed: nil))
        activeEvent = nil
    }
}


