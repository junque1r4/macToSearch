//
//  SearchPreviewView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

// This view is now integrated into the main ContentView as inline chat
// The preview functionality is handled directly in the chat bubbles
// Screenshots and snippets appear inline within the conversation flow

struct SearchPreviewView: View {
    let image: NSImage?
    let onDismiss: () -> Void
    let onSend: (String) -> Void
    
    @State private var promptText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        // This view is deprecated - functionality moved to inline chat
        // Keeping for backward compatibility
        EmptyView()
    }
}

// Image attachment handler for drag and drop
struct ImageDropDelegate: DropDelegate {
    @Binding var attachedImage: NSImage?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
            if let urlData = urlData as? Data,
               let url = URL(dataRepresentation: urlData, relativeTo: nil),
               let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.attachedImage = image
                }
            }
        }
        
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
}

#Preview {
    SearchPreviewView(
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
        onDismiss: {},
        onSend: { _ in }
    )
}