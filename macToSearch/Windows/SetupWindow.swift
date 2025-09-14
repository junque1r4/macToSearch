//
//  SetupWindow.swift
//  macToSearch
//
//  Created by Assistant on 14/09/2025.
//

import SwiftUI
import AppKit

/// Initial setup window for API key configuration
class SetupWindow: NSPanel {
    private var hostingView: NSHostingView<AnyView>?
    private var setupCoordinator: SetupCoordinator?
    var onSetupComplete: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContent()
        centerWindow()
    }

    private func setupWindow() {
        title = "Welcome to macToSearch"
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true

        animationBehavior = .documentWindow

        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 20
        contentView?.layer?.masksToBounds = true
    }

    private func setupContent() {
        setupCoordinator = SetupCoordinator()
        setupCoordinator?.onSetupComplete = { [weak self] in
            self?.onSetupComplete?()
            self?.close()
        }

        let content = SetupContainerView(coordinator: setupCoordinator!)
            .frame(width: 600, height: 500)

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
            let y = (screenFrame.height - windowFrame.height) / 2 + screenFrame.origin.y

            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func showSetup(animated: Bool = true) {
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

/// Setup coordinator for managing state
@Observable
final class SetupCoordinator {
    enum SetupStep {
        case welcome
        case apiKey
        case testing
        case complete
    }

    var currentStep: SetupStep = .welcome
    var apiKey: String = ""
    var isValidating: Bool = false
    var validationMessage: String = ""
    var validationSuccess: Bool = false
    var availableModels: [String] = []
    var selectedModel: String = "gemini-1.5-flash"
    var onSetupComplete: (() -> Void)?

    private let validator = APIKeyValidator()
    private let keychain = KeychainManager.shared

    func nextStep() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                currentStep = .apiKey
            case .apiKey:
                if !apiKey.isEmpty {
                    currentStep = .testing
                    Task {
                        await validateAndSaveKey()
                    }
                }
            case .testing:
                if validationSuccess {
                    currentStep = .complete
                }
            case .complete:
                onSetupComplete?()
            }
        }
    }

    func previousStep() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                break
            case .apiKey:
                currentStep = .welcome
            case .testing:
                currentStep = .apiKey
            case .complete:
                currentStep = .testing
            }
        }
    }

    @MainActor
    private func validateAndSaveKey() async {
        isValidating = true
        validationMessage = "Validating API key..."

        // Validate the key
        let (isValid, message) = await validator.validateGeminiKey(apiKey)

        if isValid {
            validationMessage = "Testing connection..."

            // Test actual connection
            let (success, _) = await validator.testGeminiConnection(apiKey)

            if success {
                // Get available models
                validationMessage = "Fetching available models..."
                availableModels = await validator.getAvailableModels(apiKey)

                // Save to Keychain
                if keychain.saveAPIKey(apiKey) {
                    // Also update UserDefaults for compatibility
                    UserDefaults.standard.set(apiKey, forKey: "gemini_api_key")
                    UserDefaults.standard.set(selectedModel, forKey: "gemini_model")

                    validationSuccess = true
                    validationMessage = "✅ API key validated and saved successfully!"

                    // Auto-proceed after a short delay
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    nextStep()
                } else {
                    validationSuccess = false
                    validationMessage = "❌ Failed to save API key securely"
                }
            } else {
                validationSuccess = false
                validationMessage = "❌ Connection test failed. Please check your API key."
            }
        } else {
            validationSuccess = false
            validationMessage = "❌ \(message)"
        }

        isValidating = false
    }
}

/// Setup container view
struct SetupContainerView: View {
    @Bindable var coordinator: SetupCoordinator
    @State private var gradientRotation = 0.0

    var body: some View {
        ZStack {
            // Background
            SetupBackgroundView()

            // Content
            VStack(spacing: 0) {
                // Progress indicator
                SetupProgressBar(currentStep: coordinator.currentStep)
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                // Step content
                Group {
                    switch coordinator.currentStep {
                    case .welcome:
                        WelcomeStepView(coordinator: coordinator)
                    case .apiKey:
                        APIKeyStepView(coordinator: coordinator)
                    case .testing:
                        TestingStepView(coordinator: coordinator)
                    case .complete:
                        CompleteStepView(coordinator: coordinator)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.currentStep)

                Spacer()
            }
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

/// Background view
struct SetupBackgroundView: View {
    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .blur(radius: 30)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Progress bar
struct SetupProgressBar: View {
    let currentStep: SetupCoordinator.SetupStep

    private var progress: Double {
        switch currentStep {
        case .welcome: return 0.25
        case .apiKey: return 0.5
        case .testing: return 0.75
        case .complete: return 1.0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}

/// Welcome step
struct WelcomeStepView: View {
    @Bindable var coordinator: SetupCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20)
                .padding(.top, 10)

            Text("Welcome to macToSearch")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("AI-powered Circle to Search for macOS")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "sparkles", text: "Powered by Google Gemini AI")
                FeatureRow(icon: "circle.dashed", text: "Circle to Search anything on screen")
                FeatureRow(icon: "lock.fill", text: "Your API key is stored securely")
                FeatureRow(icon: "globe", text: "Open source and privacy-focused")
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 10)

            Spacer(minLength: 5)

            Button(action: coordinator.nextStep) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.3), radius: 10)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 30)
        }
        .padding(40)
    }
}

/// Feature row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

/// API Key step
struct APIKeyStepView: View {
    @Bindable var coordinator: SetupCoordinator
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Configure Gemini API Key")
                .font(.title)
                .fontWeight(.semibold)

            Text("To use macToSearch, you'll need a Google Gemini API key")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SecureField("Enter your Gemini API key", text: $coordinator.apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 40)

            Button(action: openGeminiWebsite) {
                HStack {
                    Image(systemName: "globe")
                    Text("Get a free API key from Google AI Studio")
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 20) {
                Button(action: coordinator.previousStep) {
                    Text("Back")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                Button(action: coordinator.nextStep) {
                    HStack {
                        Text("Validate Key")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: coordinator.apiKey.isEmpty ? [.gray] : [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(coordinator.apiKey.isEmpty)
            }

            Spacer()
        }
        .padding(40)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func openGeminiWebsite() {
        if let url = URL(string: "https://makersuite.google.com/app/apikey") {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Testing step
struct TestingStepView: View {
    @Bindable var coordinator: SetupCoordinator

    var body: some View {
        VStack(spacing: 30) {
            if coordinator.isValidating {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()

                Text(coordinator.validationMessage)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: coordinator.validationSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(coordinator.validationSuccess ? .green : .red)

                Text(coordinator.validationMessage)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if coordinator.validationSuccess && !coordinator.availableModels.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Model")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Model", selection: $coordinator.selectedModel) {
                            ForEach(coordinator.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 250)
                    }
                    .padding(.top, 20)
                }

                if !coordinator.validationSuccess {
                    Button(action: { coordinator.previousStep() }) {
                        Text("Try Again")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                }
            }

            Spacer()
        }
        .padding(40)
    }
}

/// Complete step
struct CompleteStepView: View {
    @Bindable var coordinator: SetupCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .green.opacity(0.3), radius: 20)
                .padding(.top, 10)

            Text("Setup Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("macToSearch is ready to use")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                HotkeyInfo(label: "Circle to Search:", hotkey: "⌘⇧Space")
                HotkeyInfo(label: "Open Chat:", hotkey: "⌘⇧O")
                HotkeyInfo(label: "Settings:", hotkey: "⌘⇧S")
            }
            .padding(.vertical, 10)

            Spacer(minLength: 5)

            Button(action: coordinator.nextStep) {
                Text("Start Using macToSearch")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .blue.opacity(0.3), radius: 10)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 30)
        }
        .padding(40)
    }
}

/// Hotkey info row
struct HotkeyInfo: View {
    let label: String
    let hotkey: String

    var body: some View {
        HStack(spacing: 20) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)

            Text(hotkey)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                )
        }
    }
}