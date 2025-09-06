//
//  ClipboardManager.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import AppKit
import SwiftUI

class ClipboardManager: ObservableObject {
    @Published var lastClipboardContent: String = ""
    @Published var hasImage: Bool = false
    @Published var clipboardImage: NSImage?
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    @AppStorage("clipboard_monitoring") var isMonitoringEnabled: Bool = false
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard isMonitoringEnabled else { return }
        
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func toggleMonitoring() {
        isMonitoringEnabled.toggle()
        if isMonitoringEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Check for text
        if let string = pasteboard.string(forType: .string) {
            lastClipboardContent = string
            hasImage = false
            clipboardImage = nil
        }
        // Check for image
        else if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            clipboardImage = image
            hasImage = true
            lastClipboardContent = ""
        }
    }
    
    func getCurrentClipboardContent() -> (text: String?, image: NSImage?) {
        let pasteboard = NSPasteboard.general
        
        if let string = pasteboard.string(forType: .string) {
            return (string, nil)
        } else if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            return (nil, image)
        }
        
        return (nil, nil)
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copyImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}