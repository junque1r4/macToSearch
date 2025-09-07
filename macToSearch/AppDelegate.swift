//
//  AppDelegate.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import AppKit
import SwiftUI
import ScreenCaptureKit
import CoreMedia

class AppDelegate: NSObject, NSApplicationDelegate, SCStreamDelegate, SCStreamOutput {
    var overlayWindow: OverlayWindow?
    var floatingSearchWindow: FloatingSearchWindow?
    var mainWindow: NSWindow?
    var appState: AppState?
    var hotkeyManager: HotkeyManager?
    private var capturedImage: NSImage?
    private var captureStream: SCStream?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup floating search window
        setupFloatingSearchWindow()
        
        // Setup overlay window
        overlayWindow = OverlayWindow()
        
        // Setup hotkey callbacks
        setupHotkeyCallback()
        
        // Setup menu bar icon
        setupMenuBarIcon()
        
        // Hide main window if it exists
        hideMainWindow()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Reposition window when app becomes active
        repositionMainWindow()
    }
    
    func repositionMainWindow() {
        guard let window = mainWindow,
              let screen = NSScreen.main else { return }
        
        let windowWidth: CGFloat = 700
        let windowHeight: CGFloat = 600
        let screenFrame = screen.frame
        
        // Calculate position
        let xPos = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
        let yPos = screenFrame.height - windowHeight - 100 + screenFrame.origin.y
        
        // Animate to position
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(
                NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
                display: true
            )
        }
    }
    
    func setupFloatingSearchWindow() {
        // Create and show floating search window
        floatingSearchWindow = FloatingSearchWindow(appState: appState)
        floatingSearchWindow?.makeKeyAndOrderFront(nil)
    }
    
    func hideMainWindow() {
        // Hide the default SwiftUI window if it exists
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { !($0 is FloatingSearchWindow) && !($0 is OverlayWindow) }) {
                window.orderOut(nil)
                self.mainWindow = window
            }
        }
    }
    
    func setupMainWindow() {
        // Keep for compatibility but don't show by default
        // This is now only used when explicitly requested
        DispatchQueue.main.async {
            self.mainWindow = NSApp.windows.first(where: { !($0 is FloatingSearchWindow) && !($0 is OverlayWindow) })
            
            // Configure window for minimal appearance and fixed position
            if let window = self.mainWindow,
               let screen = NSScreen.main {
                
                // Window appearance
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.3)
                
                // Fixed position: center horizontally, top of screen
                let windowWidth: CGFloat = 700
                let windowHeight: CGFloat = 600
                let screenFrame = screen.frame
                
                // Calculate position
                let xPos = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
                let yPos = screenFrame.height - windowHeight - 100 + screenFrame.origin.y // 100px from top
                
                // Set frame with animation
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(
                        NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
                        display: true
                    )
                }
                
                // Make window float above others
                window.level = .floating
                
                // Make visible on all Spaces/desktops
                window.collectionBehavior = [
                    .canJoinAllSpaces,     // Visible on all Spaces
                    .transient,            // Don't show in Mission Control
                    .ignoresCycle          // Don't include in Cmd+Tab
                ]
                
                // Don't steal focus from other apps
                window.isReleasedWhenClosed = false
                window.hidesOnDeactivate = false
                
                // Smooth fade-in animation
                window.alphaValue = 0
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    window.animator().alphaValue = 1.0
                }
                
                // Make window visible without stealing focus
                window.orderFrontRegardless()
            }
        }
    }
    
    func setupHotkeyCallback() {
        hotkeyManager?.captureCallback = { [weak self] in
            self?.showDrawingOverlay()
        }
        
        hotkeyManager?.openChatCallback = { [weak self] in
            self?.showMainWindow()
        }
    }
    
    func showDrawingOverlay() {
        guard let appState = appState else { return }
        
        Task { @MainActor in
            // Hide overlay window completely before capture
            self.overlayWindow?.orderOut(nil)
            
            // Wait a moment to ensure window is hidden
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Capture using SCStream like QuickRecorder
            await captureScreenWithStream()
            
            // Show overlay after capture
            if let screenshot = capturedImage {
                appState.lastCapturedImage = screenshot
                let drawingView = DrawingOverlayView(screenshot: screenshot)
                self.overlayWindow?.showOverlay(with: drawingView, appState: appState)
            } else {
                // Fallback to simple capture
                let fallbackScreenshot = captureSimpleScreenshot()
                if let screenshot = fallbackScreenshot {
                    appState.lastCapturedImage = screenshot
                    let drawingView = DrawingOverlayView(screenshot: screenshot)
                    self.overlayWindow?.showOverlay(with: drawingView, appState: appState)
                } else {
                    print("All capture methods failed, showing overlay without screenshot")
                    let drawingView = DrawingOverlayView(screenshot: nil)
                    self.overlayWindow?.showOverlay(with: drawingView, appState: appState)
                }
            }
        }
    }
    
    // Simple screenshot method that captures everything on screen
    func captureSimpleScreenshot() -> NSImage? {
        print("Capturing simple screenshot...")
        
        // Get main screen
        guard let screen = NSScreen.main else {
            print("No main screen found")
            return nil
        }
        
        // First try: CGDisplay capture (most reliable, captures everything)
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber ?? 0
        if let cgImage = CGDisplayCreateImage(displayID.uint32Value) {
            print("CGDisplay capture successful")
            return NSImage(cgImage: cgImage, size: screen.frame.size)
        }
        
        // Second try: CGWindowList with all windows
        let screenRect = screen.frame
        if let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionAll,  // Capture ALL windows, not just on-screen
            kCGNullWindowID,
            .bestResolution
        ) {
            print("CGWindowList capture successful")
            return NSImage(cgImage: cgImage, size: screenRect.size)
        }
        
        print("Simple screenshot failed")
        return nil
    }
    
    func hideDrawingOverlay() {
        print("=== hideDrawingOverlay called ===")
        
        // Hide the overlay window
        overlayWindow?.hideOverlay()
        print("Overlay window hidden")
        
        // Update app state
        appState?.showSearchOverlay = false
        print("=== hideDrawingOverlay completed ===")
    }
    
    func showMainWindow() {
        // Now shows the floating search window's expanded state
        if let floatingWindow = floatingSearchWindow {
            if !floatingWindow.isVisible {
                floatingWindow.makeKeyAndOrderFront(nil)
            }
            floatingWindow.expand()
        } else {
            // Fallback: create floating window if it doesn't exist
            setupFloatingSearchWindow()
        }
    }
    
    func setupMenuBarIcon() {
        // Create status item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set icon - using magnifying glass similar to Spotlight
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass.circle.fill", accessibilityDescription: "macToSearch")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true // Makes it adapt to dark/light mode
            button.toolTip = "macToSearch - AI-powered search"
        }
        
        // Create menu
        statusMenu = NSMenu()
        
        // Add menu items
        statusMenu?.addItem(NSMenuItem(title: "Open Chat", action: #selector(openChatFromMenu), keyEquivalent: "o"))
        statusMenu?.items.last?.keyEquivalentModifierMask = [.command, .shift]
        statusMenu?.items.last?.target = self
        
        statusMenu?.addItem(NSMenuItem(title: "Circle to Search", action: #selector(circleToSearchFromMenu), keyEquivalent: "space"))
        statusMenu?.items.last?.keyEquivalentModifierMask = [.command, .shift]
        statusMenu?.items.last?.target = self
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        statusMenu?.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        statusMenu?.items.last?.keyEquivalentModifierMask = [.command]
        statusMenu?.items.last?.target = self
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        statusMenu?.addItem(NSMenuItem(title: "Quit macToSearch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusMenu?.items.last?.keyEquivalentModifierMask = [.command]
        
        // Assign menu to status item
        statusItem?.menu = statusMenu
    }
    
    @objc func openChatFromMenu() {
        // Show floating search window expanded
        if let floatingWindow = floatingSearchWindow {
            if !floatingWindow.isVisible {
                floatingWindow.makeKeyAndOrderFront(nil)
            }
            floatingWindow.expand()
        } else {
            setupFloatingSearchWindow()
        }
    }
    
    @objc func circleToSearchFromMenu() {
        showDrawingOverlay()
    }
    
    @objc func openPreferences() {
        // For now, expand the floating window to show settings
        // In future, could open a separate settings window
        if let floatingWindow = floatingSearchWindow {
            if !floatingWindow.isVisible {
                floatingWindow.makeKeyAndOrderFront(nil)
            }
            floatingWindow.expand()
        }
        // Send notification to open settings
        NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running even when window is closed
    }
    
    // MARK: - SCStream Capture (like QuickRecorder)
    
    private func captureScreenWithStream() async {
        do {
            // Get available content - using same method as QuickRecorder  
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
            guard let display = content.displays.first else {
                print("No displays found")
                return
            }
            
            print("Found \(content.displays.count) displays and \(content.windows.count) windows")
            
            // List all windows for debugging
            for window in content.windows {
                if let app = window.owningApplication {
                    print("Window: \(window.title ?? "untitled") - App: \(app.applicationName) - Bundle: \(app.bundleIdentifier)")
                }
            }
            
            // Create filter to capture everything on display
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            
            // Configure stream
            let configuration = SCStreamConfiguration()
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.showsCursor = false
            configuration.queueDepth = 1
            
            // Create and start stream
            captureStream = SCStream(filter: filter, configuration: configuration, delegate: self)
            
            if let stream = captureStream {
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                try await stream.startCapture()
                
                // Wait for frame to be captured
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Stop capture
                try? await stream.stopCapture()
                captureStream = nil
            }
        } catch {
            print("Stream capture failed: \(error)")
            handlePermissionError(error)
        }
    }
    
    // MARK: - SCStreamOutput Protocol
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        // Convert sample buffer to NSImage
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                capturedImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                print("Successfully captured frame from stream")
            }
        }
    }
    
    // MARK: - Permission Handling
    
    private func handlePermissionError(_ error: Error) {
        if let streamError = error as? SCStreamError {
            switch streamError.code {
            case .userDeclined:
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Permission Required"
                    alert.informativeText = "macToSearch needs screen recording permissions to capture your screen."
                    alert.addButton(withTitle: "Open Settings")
                    alert.addButton(withTitle: "Cancel")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            default:
                print("Stream error: \(error.localizedDescription)")
            }
        }
    }
}