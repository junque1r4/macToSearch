//
//  MinimalChatBubble.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct MinimalChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let image: NSImage?  // Keep for backward compatibility
    let images: [NSImage]?  // New field for multiple images
    let isUser: Bool
    let timestamp: Date = Date()
    
    // Convenience initializer for single image
    init(content: String, image: NSImage?, isUser: Bool) {
        self.content = content
        self.image = image
        self.images = image != nil ? [image!] : nil
        self.isUser = isUser
    }
    
    // Initializer for multiple images
    init(content: String, images: [NSImage]?, isUser: Bool) {
        self.content = content
        self.image = images?.first
        self.images = images
        self.isUser = isUser
    }
}

struct MinimalChatBubble: View {
    let message: MinimalChatMessage
    @State private var isHovered = false
    @State private var showActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main content bubble
            VStack(alignment: .leading, spacing: 10) {
                // Images if present
                if let images = message.images, !images.isEmpty {
                    if images.count == 1 {
                        // Single image - display larger
                        Image(nsImage: images[0])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 400, maxHeight: 250)
                            .cornerRadius(16)
                            .padding(.bottom, 4)
                    } else {
                        // Multiple images - display in a grid
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                                    Image(nsImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: 400)
                        .padding(.bottom, 4)
                    }
                }
                
                // Text content with Markdown and code block support
                if !message.content.isEmpty {
                    MarkdownTextView(content: message.content)
                }
                
                // Subtle timestamp
                if showActions {
                    HStack {
                        Text(formatTime(message.timestamp))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Spacer()
                        
                        Button(action: copyMessage) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                }
            }
            .padding(20)
            .frame(maxWidth: 500, alignment: .leading)
            .background(
                // Solid gray background like Apple Intelligence responses
                message.isUser ?
                    Color(NSColor.controlBackgroundColor).opacity(0.9) :
                    Color(NSColor.controlBackgroundColor)
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        message.isUser ?
                            Color.blue.opacity(0.15) :
                            Color.primary.opacity(0.06),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.12 : 0.06),
                radius: isHovered ? 20 : 12,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isHovered)
        }
        .padding(.horizontal, message.isUser ? 60 : 20)
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                showActions = hovering
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyMessage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.content, forType: .string)
    }
}

// Minimal chat container
struct MinimalChatContainer: View {
    @Binding var messages: [MinimalChatMessage]
    @Namespace private var bottomID
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(messages) { message in
                        MinimalChatBubble(message: message)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.9)),
                                    removal: .opacity
                                        .combined(with: .scale(scale: 0.9))
                                )
                            )
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.vertical, 20)
            }
            .onChange(of: messages.count) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
}

#Preview {
    MinimalChatContainer(messages: .constant([
        MinimalChatMessage(
            content: "What's the recipe for pasta?",
            image: nil,
            isUser: true
        ),
        MinimalChatMessage(
            content: "Here's a simple pasta recipe:\n\n1. Boil 2 liters of water\n2. Add salt to the boiling water\n3. Add pasta and cook for 8-12 minutes\n4. Drain and serve with your favorite sauce",
            image: nil,
            isUser: false
        ),
        MinimalChatMessage(
            content: "Can you show me an example?",
            image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
            isUser: true
        )
    ]))
    .frame(width: 700, height: 600)
    .background(Color.gray.opacity(0.1))
}