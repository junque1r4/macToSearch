//
//  StatusBarView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicators
            HStack(spacing: 8) {
                StatusIndicator(
                    icon: "keyboard",
                    isActive: hotkeyManager.isRegistered,
                    label: "Hotkey"
                )
                
                StatusIndicator(
                    icon: "doc.on.clipboard",
                    isActive: clipboardManager.isMonitoringEnabled,
                    label: "Clipboard"
                )
                
                StatusIndicator(
                    icon: "camera",
                    isActive: appState.isCapturing,
                    label: "Capturing"
                )
            }
            
            Spacer()
            
            // API Status
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Gemini Flash")
                    .font(.caption)
                Circle()
                    .fill(appState.geminiAPIKey.isEmpty ? Color.red : Color.green)
                    .frame(width: 6, height: 6)
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StatusIndicator: View {
    let icon: String
    let isActive: Bool
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    StatusBarView()
        .environmentObject(AppState())
        .environmentObject(HotkeyManager())
}