//
//  HRVData.swift
//  HRVConnectivityPrac
//
//  Created by Tyler Woody on 2/6/25.
//

import Foundation
import CoreData

extension HRVData {
    // Add your custom methods here
    func customMethod() {
        // Your code here
    }
    
    // For example, a computed property:
    var formattedCreationDate: String {
        guard let date = self.creationData else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
