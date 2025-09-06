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
        HStack(spacing: 16) {
            ActionButton(
                icon: "camera.viewfinder",
                title: "Capture Screen",
                subtitle: "⌘⇧Space",
                color: .blue,
                action: onScreenCapture
            )
            
            ActionButton(
                icon: "doc.on.clipboard",
                title: "Search Clipboard",
                subtitle: "From clipboard",
                color: .green,
                action: onClipboardSearch
            )
            
            ActionButton(
                icon: "text.magnifyingglass",
                title: "Text Search",
                subtitle: "Type to search",
                color: .purple,
                action: onTextSearch
            )
        }
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: 8)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    QuickActionsView(
        onScreenCapture: {},
        onClipboardSearch: {},
        onTextSearch: {}
    )
}