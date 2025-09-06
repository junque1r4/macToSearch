//
//  OverlayWindow.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import AppKit
import SwiftUI

class OverlayWindow: NSWindow {
    
    init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.styleMask.insert(.fullSizeContentView)
        
        // Make window appear above everything except screen saver
        self.canBecomeVisibleWithoutLogin = true
        self.hidesOnDeactivate = false
        
        // Set initial frame to cover entire screen
        if let screen = NSScreen.main {
            self.setFrame(screen.frame, display: true)
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // Handle keyboard events
    override func keyDown(with event: NSEvent) {
        // Check for ESC key
        if event.keyCode == 53 { // 53 is the keycode for ESC
            print("ESC key pressed - closing overlay")
            self.hideOverlay()
            
            // Notify AppDelegate to clean up
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.hideDrawingOverlay()
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    func showOverlay(with view: some View, appState: AppState) {
        // Create hosting view
        let hostingView = NSHostingView(rootView: view.environmentObject(appState))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        self.contentView = hostingView
        
        // Ensure window covers full screen first
        if let screen = NSScreen.main {
            self.setFrame(screen.frame, display: true, animate: false)
        }
        
        // Show window and make it key
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        
        // Force the window to become key and capture all events
        NSApp.activate(ignoringOtherApps: true)
        self.makeKey()
        self.makeMain()
        
        // Ensure the hosting view can receive events
        if let contentView = self.contentView {
            contentView.window?.makeFirstResponder(contentView)
        }
    }
    
    func hideOverlay() {
        self.orderOut(nil)
        self.contentView = nil
    }
}