//
//  HRVWatchApp.swift
//  HRVWatch Watch App
//
//  Created by Austin Harrison on 2/3/25.
//

import SwiftUI

@main
struct HRVWatch_Watch_AppApp:
    App {
    @StateObject private var
        mockDataSender =
        MockDataSender.shared
        
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockDataSender)
        }
    }
}
