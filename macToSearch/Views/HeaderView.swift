//
//  HeaderView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("macToSearch")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Settings Button
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                // History Button
                Button(action: {
                    // Show history
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Search History")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    HeaderView()
        .environmentObject(AppState())
}