//
//  SettingsWindow.swift
//  macToSearch
//
//  Created by Assistant on 09/09/2025.
//

import SwiftUI
import AppKit

// MARK: - Settings Window
class SettingsWindow: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var settingsCoordinator: SettingsCoordinator?
    
    init() {
        // Initialize with specific size
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
        centerWindow()
    }
    
    private func setupWindow() {
        // Window appearance
        title = "macToSearch Settings"
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        
        // Window behavior
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        
        // Animation
        animationBehavior = .documentWindow
        
        // Round corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 20
        contentView?.layer?.masksToBounds = true
    }
    
    private func setupContent() {
        settingsCoordinator = SettingsCoordinator()
        
        let content = SettingsContainerView(coordinator: settingsCoordinator!)
            .frame(width: 800, height: 600)
        
        hostingView = NSHostingView(rootView: AnyView(content))
        hostingView?.frame = contentView?.bounds ?? .zero
        hostingView?.autoresizingMask = [.width, .height]
        
        if let hostingView = hostingView {
            contentView?.addSubview(hostingView)
        }
    }
    
    private func centerWindow() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = frame
            
            let x = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x
            let y = (screenFrame.height - windowFrame.height) / 2 + screenFrame.origin.y + 50 // Slight offset up
            
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func showSettings(animated: Bool = true) {
        if animated {
            alphaValue = 0
            setFrame(frame.insetBy(dx: 20, dy: 20), display: false)
            
            makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                
                alphaValue = 1
                setFrame(frame.insetBy(dx: -20, dy: -20), display: true)
            }
        } else {
            makeKeyAndOrderFront(nil)
        }
    }
    
    override func close() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            
            alphaValue = 0
            setFrame(frame.insetBy(dx: 10, dy: 10), display: true)
        }, completionHandler: {
            super.close()
        })
    }
}

// MARK: - Settings Coordinator
@Observable
final class SettingsCoordinator {
    enum SettingsSection: String, CaseIterable {
        case general = "General"
        case appearance = "Appearance"
        case ai = "AI Provider"
        case privacy = "Privacy"
        case about = "About"
        case help = "Help"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .appearance: return "paintbrush"
            case .ai: return "sparkles"
            case .privacy: return "lock"
            case .about: return "info.circle"
            case .help: return "questionmark.circle"
            }
        }
    }
    
    var currentSection: SettingsSection = .general
    var hasUnsavedChanges = false
    var showSaveSuccess = false
    var showResetConfirmation = false
    
    func selectSection(_ section: SettingsSection) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentSection = section
        }
    }
}

// MARK: - Settings Container View
struct SettingsContainerView: View {
    @Bindable var coordinator: SettingsCoordinator
    @State private var sidebarHover: SettingsCoordinator.SettingsSection?
    @State private var gradientRotation = 0.0
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SettingsSidebar(
                coordinator: coordinator,
                hoveredSection: $sidebarHover,
                gradientRotation: gradientRotation
            )
            .frame(width: 200)
            
            Divider()
                .opacity(0.3)
            
            // Content Area
            SettingsContentArea(
                currentSection: coordinator.currentSection,
                coordinator: coordinator
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            SettingsBackgroundView()
        }
        .onAppear {
            startGradientAnimation()
        }
    }
    
    private func startGradientAnimation() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
    }
}

// MARK: - Settings Background
struct SettingsBackgroundView: View {
    var body: some View {
        ZStack {
            // Base blur layer
            Color.clear
                .background(.ultraThinMaterial)
                .blur(radius: 30)
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Noise texture (simplified version)
            Rectangle()
                .fill(
                    ImagePaint(
                        image: Image(systemName: "circle.fill"),
                        scale: 0.01
                    ).opacity(0.02)
                )
        }
    }
}

// MARK: - Settings Sidebar
struct SettingsSidebar: View {
    @Bindable var coordinator: SettingsCoordinator
    @Binding var hoveredSection: SettingsCoordinator.SettingsSection?
    let gradientRotation: Double
    
    var body: some View {
        VStack(spacing: 0) {
            // Main sections
            VStack(spacing: 8) {
                ForEach([SettingsCoordinator.SettingsSection.general,
                        .appearance,
                        .ai,
                        .privacy], id: \.self) { section in
                    SidebarButton(
                        section: section,
                        isSelected: coordinator.currentSection == section,
                        isHovered: hoveredSection == section,
                        gradientRotation: gradientRotation,
                        action: {
                            coordinator.selectSection(section)
                        }
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredSection = hovering ? section : nil
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 12)
            
            Spacer()
            
            Divider()
                .opacity(0.2)
                .padding(.horizontal, 20)
            
            // Bottom sections
            VStack(spacing: 8) {
                ForEach([SettingsCoordinator.SettingsSection.about, .help], id: \.self) { section in
                    SidebarButton(
                        section: section,
                        isSelected: coordinator.currentSection == section,
                        isHovered: hoveredSection == section,
                        gradientRotation: gradientRotation,
                        action: {
                            coordinator.selectSection(section)
                        }
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredSection = hovering ? section : nil
                        }
                    }
                }
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 12)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

// MARK: - Sidebar Button
struct SidebarButton: View {
    let section: SettingsCoordinator.SettingsSection
    let isSelected: Bool
    let isHovered: Bool
    let gradientRotation: Double
    let action: () -> Void
    
    @State private var iconRotation = 0.0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .rotationEffect(.degrees(isHovered ? 5 : 0))
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                Text(section.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            AngularGradient(
                                colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue],
                                center: .center,
                                angle: .degrees(gradientRotation)
                            ),
                            lineWidth: 1
                        )
                        .opacity(0.6)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Settings Content Area
struct SettingsContentArea: View {
    let currentSection: SettingsCoordinator.SettingsSection
    @Bindable var coordinator: SettingsCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Section Title
                Text(currentSection.rawValue)
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                
                Divider()
                    .opacity(0.2)
                    .padding(.horizontal, 30)
                
                // Content based on section
                Group {
                    switch currentSection {
                    case .general:
                        GeneralSettingsContent()
                    case .appearance:
                        AppearanceSettingsContent()
                    case .ai:
                        AIProviderSettingsContent()
                    case .privacy:
                        PrivacySettingsContent()
                    case .about:
                        AboutContent()
                    case .help:
                        HelpContent()
                    }
                }
                .padding(30)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentSection)
    }
}

// MARK: - General Settings Content
struct GeneralSettingsContent: View {
    @AppStorage("launch_at_login") private var launchAtLogin = false
    @AppStorage("show_in_menu_bar") private var showInMenuBar = true
    @AppStorage("start_minimized") private var startMinimized = false
    @AppStorage("play_sounds") private var playSounds = true
    @AppStorage("show_notifications") private var showNotifications = true
    @AppStorage("keep_on_top") private var keepOnTop = false
    @AppStorage("app_language") private var appLanguage = "System Default"
    
    // Hotkey settings from HotkeyManager
    @AppStorage("hotkey_enabled") private var captureHotkeyEnabled = true
    @AppStorage("chat_hotkey_enabled") private var chatHotkeyEnabled = true
    
    @State private var captureHotkey = "⌘⇧Space"
    @State private var clearHotkey = "⌘K"
    @State private var isRecordingHotkey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Startup Section
            SettingsSection(title: "Startup") {
                VStack(alignment: .leading, spacing: 12) {
                    GlassToggle(isOn: $launchAtLogin, label: "Launch at Login")
                    GlassToggle(isOn: $showInMenuBar, label: "Show in Menu Bar")
                    GlassToggle(isOn: $startMinimized, label: "Start Minimized")
                }
            }
            
            // Behavior Section
            SettingsSection(title: "Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    GlassToggle(isOn: $playSounds, label: "Play Sound Effects")
                    GlassToggle(isOn: $showNotifications, label: "Show Notifications")
                    GlassToggle(isOn: $keepOnTop, label: "Keep Window on Top")
                }
            }
            
            // Quick Actions Section
            SettingsSection(title: "Quick Actions") {
                VStack(alignment: .leading, spacing: 12) {
                    HotkeyRow(
                        label: "Capture Hotkey:",
                        hotkey: $captureHotkey,
                        isRecording: $isRecordingHotkey
                    )
                    
                    HotkeyRow(
                        label: "Clear Chat:",
                        hotkey: $clearHotkey,
                        isRecording: $isRecordingHotkey
                    )
                }
            }
            
            // Language Section
            SettingsSection(title: "Language") {
                GlassDropdown(
                    selection: $appLanguage,
                    options: ["System Default", "English", "Português", "Español"]
                )
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                GlassButton(
                    title: "Reset to Defaults",
                    style: .secondary,
                    action: {
                        resetToDefaults()
                    }
                )
                
                Spacer()
                
                Text("Settings save automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func resetToDefaults() {
        // Reset all settings to their default values
        launchAtLogin = false
        showInMenuBar = true
        startMinimized = false
        playSounds = true
        showNotifications = true
        keepOnTop = false
        appLanguage = "System Default"
        captureHotkeyEnabled = true
        chatHotkeyEnabled = true
        
        // Reset hotkey displays
        captureHotkey = "⌘⇧Space"
        clearHotkey = "⌘K"
    }
}

// MARK: - Glass Components
struct GlassToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 14))
        }
        .toggleStyle(GlassToggleStyle())
    }
}

struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct GlassButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(style == .primary ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(style == .primary ? Color.blue : Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: style == .primary ? .blue.opacity(0.3) : .clear, radius: isHovered ? 8 : 4)
                }
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct GlassDropdown: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Picker(selection: $selection, label: EmptyView()) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 200)
    }
}

struct HotkeyRow: View {
    let label: String
    @Binding var hotkey: String
    @Binding var isRecording: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .frame(width: 120, alignment: .leading)
            
            Text(hotkey)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecording ? Color.red : Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: isRecording)
            
            Button("Record New") {
                isRecording.toggle()
            }
            .font(.system(size: 12))
            .foregroundColor(.blue)
            .buttonStyle(.plain)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            content()
                .padding(.leading, 8)
        }
    }
}

// MARK: - Placeholder Content Views
struct AppearanceSettingsContent: View {
    var body: some View {
        Text("Appearance settings coming soon...")
            .foregroundColor(.secondary)
    }
}

struct AIProviderSettingsContent: View {
    @AppStorage("gemini_api_key") private var storedAPIKey: String = ""
    @State private var newAPIKey: String = ""
    @State private var isValidating: Bool = false
    @State private var validationMessage: String = ""
    @State private var showAPIKey: Bool = false
    @State private var isEditing: Bool = false
    @State private var availableModels: [String] = []
    @AppStorage("gemini_model") private var selectedModel: String = "gemini-1.5-flash"

    private let validator = APIKeyValidator()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // API Configuration Section
            SettingsSection(title: "Google Gemini API") {
                VStack(alignment: .leading, spacing: 16) {
                    // Current API Key Status
                    HStack {
                        Image(systemName: !storedAPIKey.isEmpty ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(!storedAPIKey.isEmpty ? .green : .red)

                        Text(!storedAPIKey.isEmpty ? "API Key Configured" : "No API Key Set")
                            .font(.system(size: 14, weight: .medium))

                        Spacer()

                        if !storedAPIKey.isEmpty && !isEditing {
                            Button("Change Key") {
                                withAnimation {
                                    isEditing = true
                                    newAPIKey = ""
                                }
                            }
                            .font(.system(size: 12))
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }
                    }

                    // Show current key (masked)
                    if !storedAPIKey.isEmpty && !isEditing {
                        HStack {
                            Text("Current Key:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            if showAPIKey {
                                Text(storedAPIKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .textSelection(.enabled)
                            } else {
                                Text("••••••••••••••••••••")
                                    .font(.system(size: 12, design: .monospaced))
                            }

                            Button(action: toggleShowAPIKey) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)

                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }

                    // Edit API Key Section
                    if isEditing || storedAPIKey.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(!storedAPIKey.isEmpty ? "Enter New API Key" : "Configure API Key")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            SecureField("Gemini API Key", text: $newAPIKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                        )
                                )

                            HStack {
                                Button("Get API Key") {
                                    openGeminiWebsite()
                                }
                                .font(.system(size: 12))
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)

                                Spacer()

                                if isEditing {
                                    Button("Cancel") {
                                        withAnimation {
                                            isEditing = false
                                            newAPIKey = ""
                                            validationMessage = ""
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                                }

                                Button(action: validateAndSaveKey) {
                                    if isValidating {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Text("Validate & Save")
                                            .font(.system(size: 12))
                                    }
                                }
                                .disabled(newAPIKey.isEmpty || isValidating)
                                .buttonStyle(.plain)
                                .foregroundColor(newAPIKey.isEmpty ? .gray : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(newAPIKey.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                )
                            }

                            if !validationMessage.isEmpty {
                                Text(validationMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(validationMessage.contains("✅") ? .green : .red)
                            }
                        }
                    }
                }
            }

            // Model Selection Section
            if !storedAPIKey.isEmpty {
                SettingsSection(title: "Model Selection") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Preferred Model:")
                                .font(.system(size: 14))
                                .frame(width: 120, alignment: .leading)

                            Picker(selection: $selectedModel, label: EmptyView()) {
                                // Default models
                                Text("gemini-1.5-flash").tag("gemini-1.5-flash")
                                Text("gemini-1.5-flash-8b").tag("gemini-1.5-flash-8b")
                                Text("gemini-1.5-pro").tag("gemini-1.5-pro")
                                Text("gemini-2.0-flash-exp").tag("gemini-2.0-flash-exp")

                                if !availableModels.isEmpty {
                                    Divider()
                                    ForEach(availableModels.filter { model in
                                        !["gemini-1.5-flash", "gemini-1.5-flash-8b", "gemini-1.5-pro", "gemini-2.0-flash-exp"].contains(model)
                                    }, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }

                        Button("Refresh Available Models") {
                            Task {
                                await refreshModels()
                            }
                        }
                        .font(.system(size: 12))
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                }
            }

            // API Usage Tips
            SettingsSection(title: "Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "lightbulb", text: "Get a free API key from Google AI Studio")
                    TipRow(icon: "lock.fill", text: "Your API key is stored locally on your device")
                    TipRow(icon: "bolt.fill", text: "Flash models are faster and more cost-effective")
                    TipRow(icon: "sparkles", text: "Pro models offer better quality for complex tasks")
                }
            }

            Spacer()

            // Danger Zone
            if !storedAPIKey.isEmpty {
                SettingsSection(title: "Danger Zone") {
                    Button("Remove API Key") {
                        removeAPIKey()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            loadCurrentKey()
            Task {
                await refreshModels()
            }
        }
    }

    private func loadCurrentKey() {
        // Already loaded via @AppStorage
    }

    private func toggleShowAPIKey() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showAPIKey.toggle()
        }
    }

    private func validateAndSaveKey() {
        Task { @MainActor in
            isValidating = true
            validationMessage = "Validating API key..."

            let (isValid, message) = await validator.validateGeminiKey(newAPIKey)

            if isValid {
                // Test connection
                validationMessage = "Testing connection..."
                let (success, _) = await validator.testGeminiConnection(newAPIKey)

                if success {
                    // Save to UserDefaults
                    storedAPIKey = newAPIKey

                    validationMessage = "✅ API key saved successfully!"
                    isEditing = false
                    newAPIKey = ""

                    // Refresh models
                    await refreshModels()

                    // Clear message after delay
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    validationMessage = ""
                } else {
                    validationMessage = "❌ Connection test failed"
                }
            } else {
                validationMessage = "❌ \(message)"
            }

            isValidating = false
        }
    }

    private func refreshModels() async {
        if !storedAPIKey.isEmpty {
            availableModels = await validator.getAvailableModels(storedAPIKey)
        }
    }

    private func removeAPIKey() {
        storedAPIKey = ""
        newAPIKey = ""
        isEditing = false
        validationMessage = "API key removed"
    }

    private func openGeminiWebsite() {
        if let url = URL(string: "https://makersuite.google.com/app/apikey") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

struct PrivacySettingsContent: View {
    var body: some View {
        Text("Privacy settings coming soon...")
            .foregroundColor(.secondary)
    }
}

struct AboutContent: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("macToSearch")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct HelpContent: View {
    var body: some View {
        Text("Help documentation coming soon...")
            .foregroundColor(.secondary)
    }
}