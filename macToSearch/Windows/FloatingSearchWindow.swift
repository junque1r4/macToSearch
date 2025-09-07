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
    private var isExpanded = false
    private var showNeonBorder = true
    private let collapsedHeight: CGFloat = 56
    private let expandedHeight: CGFloat = 520 // Slightly more height for separation
    private let searchBarWidth: CGFloat = 600
    
    init(appState: AppState? = nil) {
        self.appState = appState
        
        // Initialize with collapsed size
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: searchBarWidth, height: collapsedHeight),
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
        contentView?.layer?.cornerRadius = 28
        contentView?.layer?.masksToBounds = true
    }
    
    private func setupContent() {
        updateContent()
    }
    
    private func updateContent() {
        hostingView?.removeFromSuperview()
        
        let content = FloatingSearchInterface(
            isExpanded: isExpanded,
            showNeonBorder: showNeonBorder,
            onExpand: { [weak self] in
                self?.expand()
            },
            onCollapse: { [weak self] in
                self?.collapse()
            },
            appState: appState ?? AppState()
        )
        
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
        let yPos = screenFrame.maxY - collapsedHeight - 100 // 100px from top
        
        setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
    
    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        
        // Hide neon border after first expansion
        if showNeonBorder {
            showNeonBorder = false
            updateContent()
        }
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let currentFrame = frame
        
        // Keep X position and top Y position the same, expand downward
        let xPos = currentFrame.origin.x
        let topY = currentFrame.maxY
        let newY = topY - expandedHeight
        
        // Update corner radius for expanded state
        contentView?.layer?.cornerRadius = 20
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(
                NSRect(x: xPos, y: newY, width: searchBarWidth, height: expandedHeight),
                display: true
            )
        }
    }
    
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        
        let currentFrame = frame
        
        // Keep X position, collapse upward to original position
        let xPos = currentFrame.origin.x
        let topY = currentFrame.maxY
        let newY = topY - collapsedHeight
        
        // Update corner radius for collapsed state
        contentView?.layer?.cornerRadius = 28
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(
                NSRect(x: xPos, y: newY, width: searchBarWidth, height: collapsedHeight),
                display: true
            )
        }
    }
    
    // Handle ESC key
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 && isExpanded { // ESC key
            collapse()
        } else {
            super.keyDown(with: event)
        }
    }
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
    }
    
    // Override to allow window to become key
    override var canBecomeKey: Bool {
        return true
    }
}

// MARK: - Floating Search Interface
struct FloatingSearchInterface: View {
    let isExpanded: Bool
    let showNeonBorder: Bool
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let appState: AppState
    
    @StateObject private var geminiService = GeminiService()
    @State private var searchText = ""
    @State private var messages: [MinimalChatMessage] = []
    @State private var attachedImage: NSImage?
    @State private var isLoading = false
    @FocusState private var isSearchFocused: Bool
    @State private var animateGradient = false
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if !isExpanded {
                // Collapsed state - just search bar
                SolidSearchBar(
                    searchText: $searchText,
                    attachedImage: $attachedImage,
                    showNeonBorder: showNeonBorder,
                    onSearch: performSearch,
                    onFocus: {
                        if !isExpanded {
                            onExpand()
                        }
                    },
                    isSearchFocused: _isSearchFocused
                )
                .background(
                    // Solid dark background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(NSColor.darkGray).opacity(0.95))
                )
                .overlay(
                    // Animated gradient border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            AngularGradient(
                                colors: showNeonBorder ? 
                                    [.blue, .purple, .pink, .orange, .yellow, .green, .blue] :
                                    [.blue.opacity(0.5), .purple.opacity(0.5), .pink.opacity(0.5), .blue.opacity(0.5)],
                                center: .center,
                                angle: .degrees(gradientRotation)
                            ),
                            lineWidth: showNeonBorder ? 2 : 1.5
                        )
                        .shadow(color: .blue.opacity(0.6), radius: 10)
                        .shadow(color: .purple.opacity(0.4), radius: 15)
                )
            } else {
                // Expanded state - search bar + separate chat
                VStack(spacing: 16) { // Add space between search bar and chat
                    // Search bar - standalone at top
                    SolidSearchBar(
                        searchText: $searchText,
                        attachedImage: $attachedImage,
                        showNeonBorder: false,
                        onSearch: performSearch,
                        onFocus: {},
                        isSearchFocused: _isSearchFocused
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(NSColor.darkGray).opacity(0.95))
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
                    
                    // Chat area - separate rounded rectangle
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
                        // Glassmorphism effect for chat area only
                        ZStack {
                            GlassmorphismBackground()
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(NSColor.darkGray).opacity(0.3))
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.top, 0) // Ensure no extra padding at top
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty || attachedImage != nil else { return }
        
        // Expand if not already
        if !isExpanded {
            onExpand()
        }
        
        Task {
            await searchWithGemini(text: searchText, image: attachedImage)
        }
    }
    
    private func searchWithGemini(text: String, image: NSImage?) async {
        isLoading = true
        
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
                messages.append(MinimalChatMessage(
                    content: result,
                    image: nil,
                    isUser: false
                ))
                
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

// MARK: - Solid Search Bar
struct SolidSearchBar: View {
    @Binding var searchText: String
    @Binding var attachedImage: NSImage?
    let showNeonBorder: Bool
    let onSearch: () -> Void
    let onFocus: () -> Void
    @FocusState var isSearchFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary.opacity(0.5))
            
            // Text field
            TextField("macToSearch", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($isSearchFocused)
                .onSubmit(onSearch)
                .onChange(of: isSearchFocused) { focused in
                    if focused {
                        onFocus()
                    }
                }
            
            // Action buttons
            HStack(spacing: 8) {
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                
                // Camera button
                Button(action: captureScreen) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                // Mic button
                Button(action: {}) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func captureScreen() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.showDrawingOverlay()
        }
    }
}


// MARK: - Glassmorphism Background
struct GlassmorphismBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow  // Ultra dark with blur
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
                        colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("What can I help you find?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.6))
            
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