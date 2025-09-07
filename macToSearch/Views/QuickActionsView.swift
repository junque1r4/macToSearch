//
//  QuickActionsView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct QuickActionsView: View {
    let onScreenCapture: () -> Void
    let onClipboardSearch: () -> Void
    let onTextSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            ActionCardView(
                icon: "camera.viewfinder",
                title: "Capture Screen",
                subtitle: "⌘⇧Space",
                color: .blue,
                action: onScreenCapture
            )
            
            ActionCardView(
                icon: "doc.on.clipboard.fill",
                title: "Search Clipboard",
                subtitle: "From clipboard",
                color: .green,
                action: onClipboardSearch
            )
            
            ActionCardView(
                icon: "text.magnifyingglass",
                title: "Text Search",
                subtitle: "Type to search",
                color: .purple,
                action: onTextSearch
            )
        }
        .padding(.horizontal, 20)
    }
}

// Modern floating action button
struct ModernActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Icon container with glassmorphism
                ZStack {
                    // Background blur
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                        .cornerRadius(20)
                        .frame(width: 80, height: 80)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }
                .shadow(
                    color: color.opacity(isHovered ? 0.3 : 0.15),
                    radius: isHovered ? 15 : 10,
                    x: 0,
                    y: 5
                )
                
                // Text labels
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
                .padding(.top, 12)
            }
            .frame(width: 140)
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(response: 0.1, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

// Compact floating cards for smaller UI
struct CompactActionCards: View {
    let onScreenCapture: () -> Void
    let onClipboardSearch: () -> Void
    let onTextSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            CompactActionCard(
                icon: "camera.viewfinder",
                color: .blue,
                action: onScreenCapture
            )
            
            CompactActionCard(
                icon: "doc.on.clipboard.fill",
                color: .green,
                action: onClipboardSearch
            )
            
            CompactActionCard(
                icon: "text.magnifyingglass",
                color: .purple,
                action: onTextSearch
            )
        }
    }
}

struct CompactActionCard: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.5),
                                        color.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isHovered ? 2 : 1
                            )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(
                color: color.opacity(isHovered ? 0.3 : 0.1),
                radius: isHovered ? 12 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Full size cards
        QuickActionsView(
            onScreenCapture: {},
            onClipboardSearch: {},
            onTextSearch: {}
        )
        
        // Modern floating buttons
        HStack(spacing: 20) {
            ModernActionButton(
                icon: "camera.viewfinder",
                title: "Capture",
                subtitle: "Screenshot",
                color: .blue,
                action: {}
            )
            
            ModernActionButton(
                icon: "doc.on.clipboard.fill",
                title: "Clipboard",
                subtitle: "From clipboard",
                color: .green,
                action: {}
            )
        }
        
        // Compact cards
        CompactActionCards(
            onScreenCapture: {},
            onClipboardSearch: {},
            onTextSearch: {}
        )
    }
    .padding(40)
    .frame(width: 600, height: 500)
    .background(Color(NSColor.windowBackgroundColor))
}