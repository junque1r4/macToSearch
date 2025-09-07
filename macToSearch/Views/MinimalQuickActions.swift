//
//  MinimalQuickActions.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct MinimalQuickActions: View {
    let onScreenCapture: () -> Void
    let onClipboardSearch: () -> Void
    let onTextSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionPill(
                icon: "camera.viewfinder",
                title: "Capture",
                color: .blue,
                action: onScreenCapture
            )
            
            QuickActionPill(
                icon: "doc.on.clipboard",
                title: "Clipboard",
                color: .green,
                action: onClipboardSearch
            )
            
            QuickActionPill(
                icon: "text.magnifyingglass",
                title: "Text",
                color: .purple,
                action: onTextSearch
            )
        }
        .padding(.horizontal, 20)
    }
}

struct QuickActionPill: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isHovered ? color : .secondary.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                // Solid background like Apple Intelligence
                Color(NSColor.controlBackgroundColor)
                    .overlay(
                        isHovered ? color.opacity(0.1) : Color.clear
                    )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ? color.opacity(0.2) : Color.primary.opacity(0.06),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: isHovered ? color.opacity(0.15) : .black.opacity(0.05),
                radius: isHovered ? 10 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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

#Preview {
    VStack(spacing: 30) {
        MinimalQuickActions(
            onScreenCapture: {},
            onClipboardSearch: {},
            onTextSearch: {}
        )
        
        // Individual pills
        HStack(spacing: 10) {
            QuickActionPill(
                icon: "sparkles",
                title: "AI Magic",
                color: .purple,
                action: {}
            )
            
            QuickActionPill(
                icon: "photo",
                title: "Image",
                color: .orange,
                action: {}
            )
        }
    }
    .padding(40)
    .frame(width: 500, height: 200)
    .background(Color.gray.opacity(0.1))
}