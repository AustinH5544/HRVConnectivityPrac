//
//  DataModeManager.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/11/25.
//

import Foundation
import Combine

class DataModeManager: ObservableObject {
    static let shared = DataModeManager()
    
    // Set the default mode here (false = live, true = mock)
    @Published var isMockMode: Bool = true {
        didSet {
            print("Data mode changed to: \(isMockMode ? "Mock" : "Live")")
            // Optionally send the mode change to the paired device.
            DataSender.shared.sendModeChange(isMockMode: isMockMode)
        }
    }
}
