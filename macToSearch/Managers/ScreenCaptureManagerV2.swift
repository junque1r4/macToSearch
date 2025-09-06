//
//  ScreenCaptureManagerV2.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import ScreenCaptureKit
import SwiftUI
import CoreGraphics

@MainActor
class ScreenCaptureManagerV2: NSObject, ObservableObject {
    static let shared = ScreenCaptureManagerV2()
    
    private override init() {
        super.init()
        // DO NOT check permissions here - causes dialog
    }
    
    // Method 1: Direct capture without any pre-checks
    func captureScreenDirect() async throws -> NSImage? {
        // Don't catch errors here - let them propagate to caller
        // Get content directly when needed - this will trigger permission dialog only if needed
        let content = try await SCShareableContent.current
        
        guard let display = content.displays.first else {
            throw ScreenCaptureError.noDisplay
        }
        
        // Create filter that captures everything on screen without transparency
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)
        configuration.captureResolution = .best
        configuration.showsCursor = false
        // Ensure opaque capture
        configuration.backgroundColor = .clear
        
        let screenshot = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        return NSImage(cgImage: screenshot, size: NSSize(width: screenshot.width, height: screenshot.height))
    }
    
    // Alternative method: Capture with desktop windows included
    func captureWithDesktopWindows() async throws -> NSImage? {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        
        guard let display = content.displays.first else {
            throw ScreenCaptureError.noDisplay
        }
        
        // Include all windows to ensure we capture everything
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)
        configuration.captureResolution = .best
        configuration.showsCursor = false
        configuration.backgroundColor = .clear
        
        let screenshot = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        return NSImage(cgImage: screenshot, size: NSSize(width: screenshot.width, height: screenshot.height))
    }
    
    // Method 2: Fallback using CGWindowList (captures all visible windows)
    func captureWithCGDisplay() -> NSImage? {
        print("Attempting CGWindowList capture...")
        
        // Get the main display bounds
        guard let mainDisplay = NSScreen.main else {
            print("No main display found")
            return nil
        }
        
        let displayBounds = mainDisplay.frame
        
        // Use CGWindowListCreateImage to capture all windows on screen
        // Including desktop and all application windows
        let windowOption = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .optionIncludingWindow)
        
        // Try with desktop windows included
        guard let screenshot = CGWindowListCreateImage(
            displayBounds,
            windowOption,
            kCGNullWindowID,
            CGWindowImageOption(arrayLiteral: .bestResolution, .boundsIgnoreFraming)
        ) else {
            print("CGWindowList capture failed, trying alternative...")
            
            // Fallback: try capturing just the desktop
            guard let fallbackScreenshot = CGWindowListCreateImage(
                displayBounds,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            ) else {
                print("Fallback capture also failed")
                return nil
            }
            
            print("Fallback capture successful")
            return NSImage(cgImage: fallbackScreenshot, size: displayBounds.size)
        }
        
        print("CGWindowList capture successful")
        return NSImage(cgImage: screenshot, size: displayBounds.size)
    }
    
    
    // Method 4: Use content sharing picker (no permission needed)
    func showContentPicker(completion: @escaping (NSImage?) -> Void) {
        // Simply show the picker and let it handle everything
        SCContentSharingPicker.shared.isActive = true
        SCContentSharingPicker.shared.add(self)
        
        // The picker handles permission internally
        // User selects what to share
        // No permission dialog!
        
        completion(nil) // Picker will handle capture
    }
    
    // Simplified capture for specific area
    func captureArea(_ rect: CGRect) async -> NSImage? {
        // Try CGWindow first to avoid permission dialog
        if let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .boundsIgnoreFraming
        ) {
            return NSImage(cgImage: cgImage, size: rect.size)
        }
        
        return nil
    }
}

extension ScreenCaptureManagerV2: SCContentSharingPickerObserver {
    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        print("User cancelled picker")
    }
    
    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        print("Picker failed to start: \(error)")
    }
    
    func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        Task {
            do {
                let configuration = SCStreamConfiguration()
                
                // Get display dimensions from the main display
                if let mainDisplay = CGMainDisplayID() as CGDirectDisplayID? {
                    configuration.width = Int(CGDisplayPixelsWide(mainDisplay))
                    configuration.height = Int(CGDisplayPixelsHigh(mainDisplay))
                } else {
                    configuration.width = 1920
                    configuration.height = 1080
                }
                
                let screenshot = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: configuration
                )
                
                let image = NSImage(cgImage: screenshot, size: NSSize(width: screenshot.width, height: screenshot.height))
                
                // Process captured image
                await processCapture(image)
            } catch {
                print("Capture failed: \(error)")
            }
        }
    }
    
    private func processCapture(_ image: NSImage) async {
        // Handle the captured image
        if let appDelegate = NSApp.delegate as? AppDelegate {
            await MainActor.run {
                appDelegate.appState?.lastCapturedImage = image
                
                // Show drawing overlay
                let drawingView = DrawingOverlayView()
                appDelegate.overlayWindow?.showOverlay(with: drawingView, appState: appDelegate.appState!)
            }
        }
    }
}

enum ScreenCaptureError: LocalizedError {
    case notAuthorized
    case noDisplay
    case captureFailure
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen recording permission is required"
        case .noDisplay:
            return "No display available"
        case .captureFailure:
            return "Failed to capture screen"
        }
    }
}