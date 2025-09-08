//
//  FloatingSearchWindow.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI
import AppKit

// MARK: - Floating Search Window
class FloatingSearchWindow: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var appState: AppState?
    private let isExpanded = true  // Always expanded
    private var showNeonBorder = false  // No need for initial border animation
    private let windowHeight: CGFloat = 520  // Fixed height
    private let searchBarWidth: CGFloat = 600
    private var searchFieldFocusHandler: (() -> Void)?
    private var clearChatHandler: (() -> Void)?
    
    init(appState: AppState? = nil) {
        self.appState = appState
        
        // Initialize with expanded size
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: searchBarWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupPanel()
        setupContent()
        positionWindow()
    }
    
    private func setupPanel() {
        // Make window completely transparent and borderless
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        
        // Floating behavior
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        
        // Don't hide when app is inactive
        hidesOnDeactivate = false
        
        // Make window non-resizable and non-movable
        isMovable = false
        
        // Window can become key is handled by override below
        
        // Round corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 20  // Standard corner radius for expanded state
        contentView?.layer?.masksToBounds = true
    }
    
    private func setupContent() {
        updateContent()
    }
    
    private func updateContent() {
        hostingView?.removeFromSuperview()
        
        var content = FloatingSearchInterface(
            appState: appState ?? AppState()
        )
        // Set up the focus handler
        content.onWindowVisible = { [weak self] in
            self?.focusSearchField()
        }
        // Store clear chat handler for keyboard shortcuts
        clearChatHandler = {
            // Trigger clear chat in the interface
            NotificationCenter.default.post(name: NSNotification.Name("ClearChat"), object: nil)
        }
        
        hostingView = NSHostingView(rootView: AnyView(content))
        hostingView?.frame = contentView?.bounds ?? .zero
        hostingView?.autoresizingMask = [.width, .height]
        
        if let hostingView = hostingView {
            contentView?.addSubview(hostingView)
        }
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let xPos = (screenFrame.width - searchBarWidth) / 2 + screenFrame.origin.x
        let yPos = screenFrame.maxY - windowHeight - 100 // 100px from top
        
        setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
    
    // Expansion methods removed - window is always expanded
    
    // Handle keyboard shortcuts
    override func keyDown(with event: NSEvent) {
        // Check for Command modifier
        let hasCommand = event.modifierFlags.contains(.command)
        let hasShift = event.modifierFlags.contains(.shift)
        
        if event.keyCode == 53 { // ESC key
            // Make sure to resign first responder to release focus
            self.makeFirstResponder(nil)
            self.close() // Close the window completely
        } else if hasCommand && event.charactersIgnoringModifiers == "k" { // Command+K
            clearChatHandler?()
        } else if hasCommand && hasShift && event.charactersIgnoringModifiers == "n" { // Command+Shift+N  
            clearChatHandler?()
        } else {
            super.keyDown(with: event)
        }
    }
    
    // Also handle performKeyEquivalent for menu-like shortcuts
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let hasCommand = event.modifierFlags.contains(.command)
        let hasShift = event.modifierFlags.contains(.shift)
        
        if hasCommand && event.charactersIgnoringModifiers == "k" {
            clearChatHandler?()
            return true
        } else if hasCommand && hasShift && event.charactersIgnoringModifiers == "n" {
            clearChatHandler?()
            return true
        } else if hasCommand && !hasShift && event.charactersIgnoringModifiers == "h" {
            // Command+H for history toggle
            NotificationCenter.default.post(name: NSNotification.Name("ShowHistory"), object: nil)
            return true
        }
        
        return super.performKeyEquivalent(with: event)
    }
    
    // Override cancelOperation to catch ESC even when TextField has focus
    override func cancelOperation(_ sender: Any?) {
        print("[DEBUG] cancelOperation called - closing window")
        self.makeFirstResponder(nil)
        self.close()
    }
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
    }
    
    // Override to allow window to become key
    override var canBecomeKey: Bool {
        return true
    }
    
    // Method to focus the search field
    func focusSearchField() {
        // Make the window key and order front first
        if !self.isKeyWindow {
            self.makeKeyAndOrderFront(nil)
        }
        // Call the focus handler if set
        searchFieldFocusHandler?()
    }
}

// MARK: - Floating Search Interface
struct FloatingSearchInterface: View {
    let appState: AppState
    var onWindowVisible: (() -> Void)? = nil
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var geminiService = GeminiService()
    @StateObject private var historyManager = ChatHistoryManager()
    @State private var searchText = ""
    @State private var messages: [MinimalChatMessage] = []
    @State private var attachedImages: [NSImage] = []  // Changed to array for multiple images
    @State private var isLoading = false
    @FocusState private var isSearchFocused: Bool
    @State private var animateGradient = false
    @State private var gradientRotation: Double = 0
    @State private var showHistory = false
    @State private var selectedSession: ChatSession?
    
    private let clearChatNotification = NotificationCenter.default.publisher(for: NSNotification.Name("ClearChat"))
    private let showHistoryNotification = NotificationCenter.default.publisher(for: NSNotification.Name("ShowHistory"))
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar - always full width at top
            SolidSearchBar(
                searchText: $searchText,
                attachedImages: $attachedImages,
                onSearch: performSearch,
                onFocus: {},
                onClearChat: handleClearChat,
                onShowHistory: toggleHistory,
                isSearchFocused: _isSearchFocused
            )
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: .blue.opacity(0.6), radius: 10)
                    .shadow(color: .purple.opacity(0.4), radius: 15)
            )
            
            // Chat area + History sidebar (same level)
            HStack(spacing: 0) {
                // History sidebar (conditional)
                if showHistory {
                    HistorySidebarView(
                        selectedSession: $selectedSession,
                        currentMessages: $messages,
                        onNewChat: handleClearChat
                    )
                    .frame(width: 280)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(1)
                    
                    Divider()
                        .opacity(0.3)
                        .padding(.vertical, 8)
                }
                
                // Chat area - collapses when history is shown
                VStack(spacing: 0) {
                    if messages.isEmpty {
                        EmptyStateView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        MinimalChatContainer(messages: $messages)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Loading indicator
                    if isLoading {
                        LoadingIndicator()
                            .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    // Glassmorphism effect for chat area
                    ZStack {
                        GlassmorphismBackground()
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(maxHeight: .infinity)
        }
        // No animation needed - state is fixed
        .onAppear {
            // Set up history manager context
            historyManager.setModelContext(modelContext)
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
            // Focus search field when window appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
                onWindowVisible?()
            }
        }
        .onReceive(clearChatNotification) { _ in
            handleClearChat()
        }
        .onReceive(showHistoryNotification) { _ in
            toggleHistory()
        }
    }
    
    private func toggleHistory() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showHistory.toggle()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty || !attachedImages.isEmpty else { return }
        
        Task {
            await searchWithGemini(text: searchText, images: attachedImages)
        }
    }
    
    private func searchWithGemini(text: String, images: [NSImage]) async {
        isLoading = true
        
        // Add the new user message to the UI immediately
        await MainActor.run {
            let messageText = text.isEmpty && !images.isEmpty ? 
                (images.count == 1 ? "What's in this image?" : "What's in these images?") : text
            
            messages.append(MinimalChatMessage(
                content: messageText,
                images: images,  // Pass array of images
                isUser: true
            ))
        }
        
        do {
            // Convert existing messages to the format expected by GeminiService
            let messageHistory = messages.dropLast().map { message in
                (content: message.content, images: message.images ?? [], isUser: message.isUser)
            }
            
            // Use the new searchWithHistory method to maintain conversation context
            // For now, send only the first image to Gemini (we'll update this later)
            let result = try await geminiService.searchWithHistory(
                Array(messageHistory).map { (content: $0.content, image: $0.images.first, isUser: $0.isUser) },
                newText: text.isEmpty && !images.isEmpty ? 
                    (images.count == 1 ? "What's in this image?" : "What's in these images?") : text,
                newImage: images.first
            )
            
            await MainActor.run {
                messages.append(MinimalChatMessage(
                    content: result,
                    images: nil,
                    isUser: false
                ))
                
                searchText = ""
                attachedImages = []
                isLoading = false
                
                // Save to history
                historyManager.saveToCurrentSession(messages: messages)
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
    
    private func handleClearChat() {
        // Just clear without confirmation
        clearChat()
    }
    
    private func clearChat() {
        withAnimation(.easeOut(duration: 0.2)) {
            messages = []
            searchText = ""
            attachedImages = []
            selectedSession = nil
            historyManager.clearCurrentSession()
        }
    }
}

// MARK: - Solid Search Bar
struct SolidSearchBar: View {
    @Binding var searchText: String
    @Binding var attachedImages: [NSImage]
    let onSearch: () -> Void
    let onFocus: () -> Void
    let onClearChat: () -> Void
    let onShowHistory: () -> Void
    @FocusState var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Image preview bar (appears above the search bar)
            if !attachedImages.isEmpty {
                ImagePreviewBar(images: $attachedImages)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            HStack(spacing: 12) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                
                // Custom TextField with paste support
                PasteableTextField(
                    text: $searchText,
                    images: $attachedImages,
                    isFocused: _isSearchFocused.projectedValue,
                    onSubmit: onSearch,
                    onFocus: onFocus
                )
                
                // Action buttons
                HStack(spacing: 8) {
                    // Clear button
                    if !searchText.isEmpty || !attachedImages.isEmpty {
                        Button(action: {
                            searchText = ""
                            attachedImages = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // History button
                    Button(action: onShowHistory) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Chat History (⌘H)")
                    
                    // New Chat button (moved to right side)
                    Button(action: onClearChat) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("New Chat (⌘⇧N)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}


// MARK: - Glassmorphism Background
struct GlassmorphismBackground: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        // Adaptive material based on color scheme for better contrast
        view.material = colorScheme == .dark ? .contentBackground : .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 20
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("What can I help you find?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))
            
            Spacer()
        }
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.6)
            Text("Searching...")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
        )
    }
}

// MARK: - Adaptive Glassmorphism Modifier
extension View {
    func adaptiveGlassmorphism(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(AdaptiveGlassmorphismModifier(cornerRadius: cornerRadius))
    }
}

struct AdaptiveGlassmorphismModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Adaptive material based on color scheme
                    if colorScheme == .dark {
                        // Lighter background in dark mode for better contrast
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.gray.opacity(0.15))
                            .background(.ultraThinMaterial)
                    } else {
                        // Darker background in light mode
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black.opacity(0.05))
                            .background(.regularMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
    }
}