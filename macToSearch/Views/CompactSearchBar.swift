//
//  CompactSearchBar.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct CompactSearchBar: View {
    @Binding var searchText: String
    @Binding var attachedImage: NSImage?
    let onSearch: () -> Void
    let onScreenCapture: () -> Void
    @FocusState var isSearchFocused: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Image preview if attached
            if let image = attachedImage {
                HStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                        .cornerRadius(8)
                        .overlay(
                            // Remove button
                            Button(action: {
                                withAnimation(.spring(response: 0.2)) {
                                    attachedImage = nil
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 18, height: 18)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: -4, y: -4),
                            alignment: .topTrailing
                        )
                    
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
            
            // Search field with actions
            HStack(spacing: 10) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSearchFocused ? .blue : .secondary.opacity(0.7))
                    .animation(.spring(response: 0.2), value: isSearchFocused)
                
                // Text field
                TextField("macToSearch", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isSearchFocused)
                    .onSubmit {
                        if !searchText.isEmpty || attachedImage != nil {
                            onSearch()
                        }
                    }
                
                // Action buttons
                HStack(spacing: 8) {
                    // Clear button
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.2)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Screen capture button
                    Button(action: onScreenCapture) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Capture screen area")
                    
                    // Mic button
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Voice input")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                isSearchFocused ? 
                                Color.blue.opacity(0.3) : 
                                Color.primary.opacity(0.08),
                                lineWidth: isSearchFocused ? 1.2 : 0.5
                            )
                    )
            )
            .shadow(
                color: isSearchFocused ? .blue.opacity(0.1) : .black.opacity(0.05),
                radius: isSearchFocused ? 12 : 6,
                x: 0,
                y: isSearchFocused ? 4 : 2
            )
            .scaleEffect(isSearchFocused ? 1.01 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSearchFocused)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactSearchBar(
            searchText: .constant(""),
            attachedImage: .constant(nil),
            onSearch: {},
            onScreenCapture: {}
        )
        
        CompactSearchBar(
            searchText: .constant("Search query"),
            attachedImage: .constant(NSImage(systemSymbolName: "photo", accessibilityDescription: nil)),
            onSearch: {},
            onScreenCapture: {}
        )
    }
    .padding(30)
    .frame(width: 400)
    .background(Color.gray.opacity(0.1))
}