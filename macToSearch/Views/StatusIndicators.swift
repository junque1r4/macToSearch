//
//  StatusIndicators.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct ModernStatusIndicator: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isCapturing ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            
            Text(appState.isCapturing ? "Capturing" : "Ready")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            if !appState.lastExtractedText.isEmpty {
                Divider()
                    .frame(height: 12)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

struct GeminiIndicator: View {
    @EnvironmentObject var appState: AppState
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            if appState.isLoading {
                // Animated sparkles when loading
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                
                Text("Thinking...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Gemini Flash")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            appState.isLoading ?
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.primary.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(
            color: appState.isLoading ? .blue.opacity(0.2) : .clear,
            radius: appState.isLoading ? 8 : 0
        )
    }
}

#Preview {
    HStack {
        ModernStatusIndicator()
        Spacer()
        GeminiIndicator()
    }
    .padding()
    .frame(width: 400)
    .environmentObject(AppState())
}