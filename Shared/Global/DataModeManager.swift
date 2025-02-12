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
    
    @Published var isMockMode: Bool = true {
        didSet {
            print("Data mode changed to: \(isMockMode ? "Mock" : "Live")")
            // Optionally, send out the mode change to the paired device.
            DataSender.shared.sendModeChange(isMockMode: isMockMode)
        }
    }
}
