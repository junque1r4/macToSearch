//
//  PasteableTextField.swift
//  macToSearch
//
//  Created by Assistant on 07/09/2025.
//

import SwiftUI
import AppKit

// MARK: - Custom NSTextField that handles paste
class CustomNSTextField: NSTextField {
    var onPasteImages: (([NSImage]) -> Void)?
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Check for Command+V
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
            // Check pasteboard for images
            let pasteboard = NSPasteboard.general
            
            // Try to read images from pasteboard
            if let images = readImagesFromPasteboard(pasteboard) {
                onPasteImages?(images)
                return true  // We handled the paste
            }
        }
        
        // Let the default handler process other events (including text paste)
        return super.performKeyEquivalent(with: event)
    }
    
    private func readImagesFromPasteboard(_ pasteboard: NSPasteboard) -> [NSImage]? {
        var images: [NSImage] = []
        
        // Check for file URLs (when copying files from Finder)
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileURLs {
                // Check if it's an image file
                if let uti = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                   UTType(uti)?.conforms(to: .image) == true {
                    if let image = NSImage(contentsOf: url) {
                        images.append(image)
                    }
                }
            }
        }
        
        // Check for direct image data
        if images.isEmpty {
            // Try to read images directly
            if let pastedImages = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
                images.append(contentsOf: pastedImages)
            }
        }
        
        return images.isEmpty ? nil : images
    }
}

// MARK: - NSViewRepresentable wrapper
struct PasteableTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var images: [NSImage]
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onFocus: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> CustomNSTextField {
        let textField = CustomNSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = "macToSearch"
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .labelColor  // Adaptive color for text
        textField.drawsBackground = false  // Ensure transparent background
        
        // Set up paste handler
        textField.onPasteImages = { pastedImages in
            // Add pasted images to the array
            DispatchQueue.main.async {
                images.append(contentsOf: pastedImages)
            }
        }
        
        // Set up action for return key
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.onEnterPressed(_:))
        
        return textField
    }
    
    func updateNSView(_ nsView: CustomNSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // Update focus state
        if isFocused.wrappedValue && nsView.window?.firstResponder != nsView {
            nsView.window?.makeFirstResponder(nsView)
        } else if !isFocused.wrappedValue && nsView.window?.firstResponder == nsView {
            nsView.window?.makeFirstResponder(nil)
        }
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PasteableTextField
        
        init(_ parent: PasteableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.isFocused.wrappedValue = true
            parent.onFocus()
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.isFocused.wrappedValue = false
        }
        
        @objc func onEnterPressed(_ sender: NSTextField) {
            parent.onSubmit()
        }
    }
}

// For handling UTTypes
import UniformTypeIdentifiers

extension UTType {
    static let imageTypes: [UTType] = [.png, .jpeg, .gif, .tiff, .bmp, .webP, .heic, .heif]
}