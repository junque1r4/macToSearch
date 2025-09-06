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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
            
            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    QuickActionsView(
                        onScreenCapture: captureScreen,
                        onClipboardSearch: searchClipboard,
                        onTextSearch: { }
                    )
                    
                    // Search Bar
                    SearchBarView(searchText: $searchText) {
                        performTextSearch()
                    }
                    
                    // Results Display
                    if appState.isLoading {
                        ProgressView("Searching...")
                            .padding()
                    } else if !appState.searchResults.isEmpty {
                        ResultsView(results: appState.searchResults)
                    }
                    
                    // Error Display
                    if let error = appState.errorMessage {
                        ErrorView(message: error)
                    }
                }
                .padding()
            }
            
            // Status Bar
            StatusBarView()
        }
        .frame(width: 800, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupHotkey()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(hotkeyManager)
        }
    }
    
    private func setupHotkey() {
        hotkeyManager.captureCallback = {
            // Use AppDelegate to show overlay with screen capture
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.showDrawingOverlay()
            }
        }
    }
    
    private func captureScreen() {
        // Use AppDelegate to show overlay with screen capture
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showDrawingOverlay()
        }
    }
    
    private func searchClipboard() {
        let (text, image) = clipboardManager.getCurrentClipboardContent()
        
        Task {
            if let text = text {
                await searchWithGemini(text: text, image: nil)
            } else if let image = image {
                appState.lastCapturedImage = image
                
                // Extract text if possible
                let ocrManager = OCRManager()
                if let extractedText = try? await ocrManager.extractText(from: image) {
                    appState.lastExtractedText = extractedText
                }
                
                await searchWithGemini(text: appState.lastExtractedText, image: image)
            } else {
                appState.errorMessage = "No content found in clipboard"
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
        
        do {
            let result: String
            
            if let image = image {
                result = try await geminiService.searchWithImage(image, text: text.isEmpty ? "What's in this image?" : text)
            } else {
                result = try await geminiService.searchWithText(text)
            }
            
            await MainActor.run {
                appState.searchResults = result
                appState.isLoading = false
                
                // Save to history
                saveToHistory(text: text, result: result, image: image)
            }
        } catch {
            await MainActor.run {
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
