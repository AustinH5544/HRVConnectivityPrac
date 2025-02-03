//
//  HRVConnectivityPracApp.swift
//  HRVConnectivityPrac
//
//  Created by Austin Harrison on 2/3/25.
//

import SwiftUI
import SwiftData

@main
struct HRVMockTestApp: App {
    @StateObject private var connectivityManager = PhoneConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}
