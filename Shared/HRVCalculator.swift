//
//  HRVCalculator.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/4/25.
//

import Foundation
import Combine

/// Represents a single heart beat with its timestamp and heart rate.
struct Beat {
    let timestamp: Date
    let heartRate: Double
    
    /// Calculate IBI (Inter-Beat Interval) in milliseconds.
    /// (IBI = 60000 / BPM)
    var ibi: Double {
        return 60000.0 / heartRate
    }
}

/// HRVCalculator maintains a rolling window of beats (default 5 minutes)
/// and computes HRV metrics such as RMSSD and SDNN.
class HRVCalculator: ObservableObject {
    /// Window size in seconds. Default is 5 minutes (300 seconds).
    var windowSize: TimeInterval = 300
    
    /// The collected beats within the current window.
    @Published private(set) var beats: [Beat] = []
    
    /// Computed RMSSD (Root Mean Square of Successive Differences)
    /// RMSSD is defined as the square root of the mean of the squared differences
    /// between successive IBI values. Requires at least two beats.
    var rmssd: Double? {
        let ibis = beats.map { $0.ibi }
        guard ibis.count >= 2 else { return nil }
        
        // Compute successive differences and square them.
        var squaredDiffs: [Double] = []
        for i in 1..<ibis.count {
            let diff = ibis[i] - ibis[i - 1]
            squaredDiffs.append(diff * diff)
        }
        
        // Calculate the mean of the squared differences.
        let meanSquaredDiff = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
        return sqrt(meanSquaredDiff)
    }
    
    /// Computed SDNN (Standard Deviation of NN intervals)
    /// SDNN is the standard deviation of all IBI values in the current window.
    var sdnn: Double? {
        let ibis = beats.map { $0.ibi }
        guard !ibis.isEmpty else { return nil }
        
        let mean = ibis.reduce(0, +) / Double(ibis.count)
        let variance = ibis.reduce(0) { $0 + pow($1 - mean, 2) } / Double(ibis.count)
        return sqrt(variance)
    }
    
    /// Adds a new beat to the rolling window.
    /// This function also prunes any beats older than the window size.
    func addBeat(heartRate: Double, at timestamp: Date = Date()) {
        let newBeat = Beat(timestamp: timestamp, heartRate: heartRate)
        beats.append(newBeat)
        pruneOldBeats(relativeTo: timestamp)
    }
    
    /// Removes beats that are older than the specified rolling window size.
    private func pruneOldBeats(relativeTo currentTime: Date) {
        beats = beats.filter { currentTime.timeIntervalSince($0.timestamp) <= windowSize }
    }
}
