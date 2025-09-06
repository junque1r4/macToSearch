//
//  SettingsView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @StateObject private var geminiService = GeminiService()
    
    @AppStorage("gemini_api_key") private var geminiAPIKey: String = ""
    @AppStorage("gemini_model") private var selectedModel: String = "gemini-1.5-flash"
    @AppStorage("clipboard_monitoring") private var clipboardMonitoring: Bool = false
    @AppStorage("hotkey_enabled") private var hotkeyEnabled: Bool = true
    
    @State private var showAPIKey = false
    @State private var tempAPIKey = ""
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AISettingsView(
                geminiAPIKey: $geminiAPIKey,
                selectedModel: $selectedModel,
                showAPIKey: $showAPIKey,
                tempAPIKey: $tempAPIKey
            )
            .tabItem {
                Label("AI", systemImage: "sparkles")
            }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("clipboard_monitoring") private var clipboardMonitoring: Bool = false
    @AppStorage("launch_at_login") private var launchAtLogin: Bool = false
    @AppStorage("show_in_menu_bar") private var showInMenuBar: Bool = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Monitor Clipboard", isOn: $clipboardMonitoring)
                    .help("Automatically detect when you copy text or images")
                
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .help("Start macToSearch when you log in")
                
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                    .help("Show macToSearch icon in the menu bar")
            }
            
            Section("Privacy") {
                Text("macToSearch requires Screen Recording permission to capture screenshots.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Open Privacy Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
            }
        }
        .padding()
    }
}

struct AISettingsView: View {
    @Binding var geminiAPIKey: String
    @Binding var selectedModel: String
    @Binding var showAPIKey: Bool
    @Binding var tempAPIKey: String
    
    let availableModels = [
        "gemini-1.5-flash",
        "gemini-1.5-flash-8b",
        "gemini-1.5-pro",
        "gemini-2.0-flash"
    ]
    
    var body: some View {
        Form {
            Section("Gemini API") {
                HStack {
                    if showAPIKey {
                        TextField("API Key", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $tempAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: {
                        showAPIKey.toggle()
                    }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    
                    Button("Save") {
                        geminiAPIKey = tempAPIKey
                    }
                    .disabled(tempAPIKey.isEmpty)
                }
                
                Link("Get your Gemini API Key", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                    .font(.caption)
            }
            
            Section("Model Selection") {
                Picker("Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                
                Text("Flash models are optimized for speed and cost-efficiency")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Usage") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Free Tier:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("• 1,500 requests/day")
                        .font(.caption)
                    Text("• Free input/output tokens")
                        .font(.caption)
                    
                    Text("Paid Tier:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.top, 4)
                    Text("• $0.075 per 1M input tokens")
                        .font(.caption)
                    Text("• $0.30 per 1M output tokens")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            tempAPIKey = geminiAPIKey
        }
    }
}

struct ShortcutsSettingsView: View {
    @AppStorage("hotkey_enabled") private var hotkeyEnabled: Bool = true
    @State private var recordingShortcut = false
    
    var body: some View {
        Form {
            Section("Global Shortcuts") {
                HStack {
                    Toggle("Enable Global Shortcut", isOn: $hotkeyEnabled)
                    
                    Spacer()
                    
                    Text("⌘⇧Space")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
                
                Text("Press this shortcut anywhere to trigger screen capture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("App Shortcuts") {
                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRow(shortcut: "⌘N", description: "New Search")
                    ShortcutRow(shortcut: "⌘,", description: "Settings")
                    ShortcutRow(shortcut: "⌘H", description: "Show History")
                    ShortcutRow(shortcut: "⌘Q", description: "Quit App")
                }
            }
        }
        .padding()
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("macToSearch")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("AI-powered search for macOS")
                .font(.body)
            
            VStack(spacing: 8) {
                Text("Circle to Search for Mac")
                    .font(.caption)
                
                Text("Capture, Extract, Search - All with AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            Spacer()
            
            Text("© 2025 macToSearch")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(HotkeyManager())
}