//
//  ScreenCaptureManager.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import ScreenCaptureKit
import SwiftUI
import CoreGraphics

@MainActor
class ScreenCaptureManager: NSObject, ObservableObject {
    static let shared = ScreenCaptureManager()
    
    @Published var availableContent: SCShareableContent?
    @Published var selectedDisplay: SCDisplay?
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        // Don't check authorization in init to avoid permission dialog
        // Check permission status without triggering dialog
        self.isAuthorized = CGPreflightScreenCaptureAccess()
    }
    
    func hasPermission() -> Bool {
        // Use CGPreflightScreenCaptureAccess to check without triggering dialog
        return CGPreflightScreenCaptureAccess()
    }
    
    func checkAuthorization() async {
        // Only check if we don't already have permission
        if !hasPermission() {
            // This will trigger the permission dialog only when needed
            do {
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                isAuthorized = true
            } catch {
                isAuthorized = false
                print("Screen recording permission required: \(error)")
            }
        } else {
            isAuthorized = true
        }
    }
    
    func refreshAvailableContent() async {
        // Only refresh if we have permission to avoid dialog
        guard hasPermission() else {
            print("No screen recording permission, skipping content refresh")
            return
        }
        
        do {
            availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            selectedDisplay = availableContent?.displays.first
        } catch {
            print("Failed to get available content: \(error)")
        }
    }
    
    func captureScreen(cropRect: CGRect? = nil) async throws -> NSImage? {
        // Check permission without triggering dialog
        guard hasPermission() else {
            throw CaptureError.notAuthorized
        }
        
        // Get display if not already available
        if selectedDisplay == nil {
            await refreshAvailableContent()
        }
        
        guard let display = selectedDisplay else {
            throw CaptureError.noDisplay
        }
        
        // Create filter that captures everything on screen without transparency
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        
        if let cropRect = cropRect {
            configuration.sourceRect = cropRect
        }
        
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
    
    func captureFullScreen() async throws -> NSImage? {
        return try await captureScreen(cropRect: nil)
    }
    
    func captureSelectedArea(startPoint: CGPoint, endPoint: CGPoint) async throws -> NSImage? {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        let cropRect = CGRect(x: minX, y: minY, width: width, height: height)
        return try await captureScreen(cropRect: cropRect)
    }
    
    // Alternative capture method using CGWindowList
    func captureScreenWithCGWindowList() -> NSImage? {
        print("Attempting CGWindowList capture in ScreenCaptureManager...")
        
        // Get the main display bounds
        guard let mainDisplay = NSScreen.main else {
            print("No main display found")
            return nil
        }
        
        let displayBounds = mainDisplay.frame
        
        // Use CGWindowListCreateImage to capture all visible windows
        let windowOption = CGWindowListOption.optionOnScreenOnly
        
        guard let screenshot = CGWindowListCreateImage(
            displayBounds,
            windowOption,
            kCGNullWindowID,
            CGWindowImageOption.bestResolution
        ) else {
            print("CGWindowList capture failed")
            return nil
        }
        
        print("CGWindowList capture successful")
        return NSImage(cgImage: screenshot, size: displayBounds.size)
    }
}

enum CaptureError: Error {
    case notAuthorized
    case noDisplay
    case captureFailure
    
    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "Screen recording permission is required. Please grant permission in System Settings > Privacy & Security > Screen Recording."
        case .noDisplay:
            return "No display available for capture"
        case .captureFailure:
            return "Failed to capture screen"
        }
    }
}