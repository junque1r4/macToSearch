//
//  ContentView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var hotkeyManager: HotkeyManager
    @StateObject private var geminiService = GeminiService()
    @StateObject private var clipboardManager = ClipboardManager()
    
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var attachedImage: NSImage?
    @State private var messages: [MinimalChatMessage] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Floating search bar at top
            FloatingSearchBar(
                searchText: $searchText,
                attachedImage: $attachedImage,
                onSearch: performTextSearch
            )
            .padding(.top, 20)
            
            // Chat messages or empty state
            if messages.isEmpty {
                // Minimal empty state
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("What can I help you with today?")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("Search anything with AI-powered assistance")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    // Minimal quick actions
                    MinimalQuickActions(
                        onScreenCapture: captureScreen,
                        onClipboardSearch: searchClipboard,
                        onTextSearch: { }
                    )
                    .padding(.top, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
                Spacer()
            } else {
                // Minimal chat view
                MinimalChatContainer(messages: $messages)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            }
            
            // Minimal status indicators (only when loading)
            if appState.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Thinking...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 700, height: 600)
        .background(
            // Light background similar to Apple Intelligence
            Color(NSColor.windowBackgroundColor).opacity(0.001)
        )
        .onAppear {
            setupHotkey()
        }
        .onChange(of: appState.lastCapturedImage) { newImage in
            if let image = newImage {
                // Add captured image to the search bar
                attachedImage = image
                // Clear the app state
                appState.lastCapturedImage = nil
            }
        }
        .onDrop(of: [.fileURL], delegate: ImageDropDelegate(attachedImage: $attachedImage))
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(hotkeyManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettings"))) { _ in
            showSettings = true
        }
    }
    
    private func setupHotkey() {
        hotkeyManager.captureCallback = {
            // Use AppDelegate to show overlay with screen capture
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.showDrawingOverlay()
            }
        }
        
        hotkeyManager.openChatCallback = {
            // Use AppDelegate to show main window
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.showMainWindow()
            }
        }
    }
    
    private func captureScreen() {
        // Use AppDelegate to show overlay with screen capture
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showDrawingOverlay()
        }
        
        // When the capture is complete, the image will be added to attachedImage
        // through the app state
    }
    
    private func searchClipboard() {
        let (text, image) = clipboardManager.getCurrentClipboardContent()
        
        Task {
            if let text = text {
                searchText = text
                await searchWithGemini(text: text, image: nil)
            } else if let image = image {
                appState.lastCapturedImage = image
                attachedImage = image
                
                // Extract text if possible
                let ocrManager = OCRManager()
                if let extractedText = try? await ocrManager.extractText(from: image) {
                    appState.lastExtractedText = extractedText
                    searchText = extractedText
                }
                
                await searchWithGemini(text: searchText.isEmpty ? "What's in this image?" : searchText, image: image)
            } else {
                await MainActor.run {
                    messages.append(MinimalChatMessage(
                        content: "No content found in clipboard",
                        image: nil,
                        isUser: false
                    ))
                }
            }
        }
    }
    
    private func performTextSearch() {
        guard !searchText.isEmpty else { return }
        
        Task {
            await searchWithGemini(text: searchText, image: nil)
        }
    }
    
    private func searchWithGemini(text: String, image: NSImage?) async {
        appState.isLoading = true
        appState.errorMessage = nil
        
        // Add user message to chat
        await MainActor.run {
            messages.append(MinimalChatMessage(content: text, image: image, isUser: true))
        }
        
        do {
            let result: String
            
            if let image = image {
                result = try await geminiService.searchWithImage(image, text: text.isEmpty ? "What's in this image?" : text)
            } else {
                result = try await geminiService.searchWithText(text)
            }
            
            await MainActor.run {
                // Add AI response to chat
                messages.append(MinimalChatMessage(content: result, image: nil, isUser: false))
                
                appState.searchResults = result
                appState.isLoading = false
                
                // Clear search text and image
                searchText = ""
                attachedImage = nil
                
                // Save to history
                saveToHistory(text: text, result: result, image: image)
            }
        } catch {
            await MainActor.run {
                // Add error message to chat
                messages.append(MinimalChatMessage(
                    content: "Sorry, I encountered an error: \(error.localizedDescription)",
                    image: nil,
                    isUser: false
                ))
                
                appState.errorMessage = error.localizedDescription
                appState.isLoading = false
            }
        }
    }
    
    private func saveToHistory(text: String, result: String, image: NSImage?) {
        // This will be implemented with SwiftData
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(HotkeyManager())
}
