//
//  macToSearchApp.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct macToSearchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var hotkeyManager = HotkeyManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SearchHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(hotkeyManager)
                .onAppear {
                    // Share instances with AppDelegate after initialization
                    appDelegate.appState = appState
                    appDelegate.hotkeyManager = hotkeyManager
                    appDelegate.setupHotkeyCallback()
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(hotkeyManager)
        }
    }
}
