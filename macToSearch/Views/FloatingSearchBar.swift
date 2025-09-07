//
//  FloatingSearchBar.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct FloatingSearchBar: View {
    @Binding var searchText: String
    @Binding var attachedImage: NSImage?
    let onSearch: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Image preview if attached (inline, minimal)
            if let image = attachedImage {
                HStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .overlay(
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    attachedImage = nil
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 20, height: 20)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: -5, y: -5),
                            alignment: .topTrailing
                        )
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
            
            // Main search bar
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isTextFieldFocused ? .blue : .secondary.opacity(0.8))
                    .animation(.spring(response: 0.3), value: isTextFieldFocused)
                
                TextField("macToSearch", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .regular))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !searchText.isEmpty {
                            onSearch()
                        }
                    }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 10) {
                    // Clear button
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Mic button
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isHovered ? .blue : .secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                // Solid gray background like Apple Intelligence
                Color(NSColor.controlBackgroundColor)
            )
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        isTextFieldFocused ?
                        Color.blue.opacity(0.3) :
                        Color.primary.opacity(0.08),
                        lineWidth: isTextFieldFocused ? 1.5 : 0.5
                    )
            )
            .shadow(
                color: isTextFieldFocused ? .blue.opacity(0.15) : .black.opacity(0.08),
                radius: isTextFieldFocused ? 20 : 12,
                x: 0,
                y: isTextFieldFocused ? 8 : 4
            )
            .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isTextFieldFocused)
        }
        .padding(.horizontal, 20)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        FloatingSearchBar(
            searchText: .constant(""),
            attachedImage: .constant(nil),
            onSearch: {}
        )
        
        FloatingSearchBar(
            searchText: .constant("How to make pasta"),
            attachedImage: .constant(nil),
            onSearch: {}
        )
        
        FloatingSearchBar(
            searchText: .constant("What's in this image?"),
            attachedImage: .constant(NSImage(systemSymbolName: "photo", accessibilityDescription: nil)),
            onSearch: {}
        )
    }
    .padding(40)
    .frame(width: 600)
    .background(Color.gray.opacity(0.1))
}