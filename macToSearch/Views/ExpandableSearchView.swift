//
//  ExpandableSearchView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct ExpandableSearchView: View {
    let onCollapse: () -> Void
    
    @StateObject private var geminiService = GeminiService()
    @StateObject private var clipboardManager = ClipboardManager()
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var messages: [MinimalChatMessage] = []
    @State private var attachedImage: NSImage?
    @State private var isLoading = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search bar
            VStack(spacing: 0) {
                // Drag handle and close button
                HStack {
                    // Drag handle (visual only)
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: onCollapse) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 12)
                    .padding(.top, 12)
                }
                
                // Compact Search Bar
                CompactSearchBar(
                    searchText: $searchText,
                    attachedImage: $attachedImage,
                    onSearch: performSearch,
                    onScreenCapture: captureScreen,
                    isSearchFocused: _isSearchFocused
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                // Translucent background with blur
                VisualEffectBackground()
            )
            
            Divider()
                .opacity(0.3)
            
            // Chat messages area
            if messages.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("What can I help you find?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                    
                    Text("Search, capture screen, or paste content")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            } else {
                // Chat view
                CompactChatView(messages: $messages)
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
            
            // Loading indicator
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Searching...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            // Focus search field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty || attachedImage != nil else { return }
        
        Task {
            await searchWithGemini(text: searchText, image: attachedImage)
        }
    }
    
    private func captureScreen() {
        // Collapse the panel first
        onCollapse()
        
        // Then trigger screen capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.showDrawingOverlay()
            }
        }
    }
    
    private func searchWithGemini(text: String, image: NSImage?) async {
        isLoading = true
        
        // Add user message
        await MainActor.run {
            messages.append(MinimalChatMessage(
                content: text.isEmpty && image != nil ? "What's in this image?" : text,
                image: image,
                isUser: true
            ))
        }
        
        do {
            let result: String
            
            if let image = image {
                result = try await geminiService.searchWithImage(
                    image,
                    text: text.isEmpty ? "What's in this image?" : text
                )
            } else {
                result = try await geminiService.searchWithText(text)
            }
            
            await MainActor.run {
                // Add AI response
                messages.append(MinimalChatMessage(
                    content: result,
                    image: nil,
                    isUser: false
                ))
                
                // Clear input
                searchText = ""
                attachedImage = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages.append(MinimalChatMessage(
                    content: "Sorry, I encountered an error: \(error.localizedDescription)",
                    image: nil,
                    isUser: false
                ))
                isLoading = false
            }
        }
    }
}

// Visual effect background for translucency
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}