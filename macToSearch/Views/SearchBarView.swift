//
//  SearchBarView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovered = false
    @State private var showMicButton = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon with animation
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: isTextFieldFocused ? [.blue, .purple] : [Color.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isTextFieldFocused ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isTextFieldFocused)
            
            // Text field
            TextField("macToSearch", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSearch()
                }
            
            // Action buttons
            HStack(spacing: 8) {
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Mic button (like Gemini)
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
                
                // Send button (like sparkles in Gemini)
                if !searchText.isEmpty {
                    Button(action: onSearch) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Glassmorphism background
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    .cornerRadius(24)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border with gradient
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: isTextFieldFocused ? 
                                [Color.blue.opacity(0.5), Color.purple.opacity(0.3)] :
                                [Color.primary.opacity(0.1), Color.primary.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isTextFieldFocused ? 2 : 1
                    )
            }
        )
        .shadow(
            color: isTextFieldFocused ? .blue.opacity(0.2) : .black.opacity(0.1),
            radius: isTextFieldFocused ? 20 : 10,
            x: 0,
            y: 5
        )
        .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTextFieldFocused)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Modern search bar with inline image support
struct ModernSearchBarView: View {
    @Binding var searchText: String
    @Binding var attachedImage: NSImage?
    let onSearch: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image preview if attached
            if let image = attachedImage {
                HStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Button(action: {
                                withAnimation(.spring()) {
                                    attachedImage = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .offset(x: -4, y: -4),
                            alignment: .topTrailing
                        )
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Search bar
            SearchBarView(searchText: $searchText, onSearch: onSearch)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        SearchBarView(searchText: .constant(""), onSearch: {})
        
        SearchBarView(searchText: .constant("What is this code doing?"), onSearch: {})
        
        ModernSearchBarView(
            searchText: .constant("Analyze this screenshot"),
            attachedImage: .constant(NSImage(systemSymbolName: "photo", accessibilityDescription: nil)),
            onSearch: {}
        )
    }
    .padding(40)
    .frame(width: 600)
    .background(Color(NSColor.windowBackgroundColor))
}
