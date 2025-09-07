//
//  ChatBubbleView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let image: NSImage?
    let isUser: Bool
    let timestamp: Date = Date()
}

struct ChatBubbleView: View {
    let message: ChatMessage
    @State private var isHovered = false
    @State private var showActions = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if !message.isUser {
                // AI Avatar
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            } else {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Message bubble
                VStack(alignment: .leading, spacing: 8) {
                    // Image preview if present
                    if let image = message.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                    
                    // Text content
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 14))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if message.isUser {
                            // User message with gradient
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            // AI message with material effect
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.regularMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                    }
                )
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                
                // Timestamp and actions
                HStack(spacing: 8) {
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if showActions {
                        HStack(spacing: 4) {
                            Button(action: copyMessage) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            
                            Button(action: shareMessage) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if message.isUser {
                // User Avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            } else {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
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
    
    private func shareMessage() {
        // Implement share functionality
    }
}

// Chat container view with scroll
struct ChatContainerView: View {
    @Binding var messages: [ChatMessage]
    @Namespace private var bottomID
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: message.isUser ? .bottomTrailing : .bottomLeading)
                                        .combined(with: .opacity),
                                    removal: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                )
                            )
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.vertical)
            }
            .background(Color.clear)
            .onChange(of: messages.count) { _ in
                withAnimation(.spring()) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
}

#Preview {
    VStack {
        ChatContainerView(messages: .constant([
            ChatMessage(content: "Hello, how can I help you today?", image: nil, isUser: false),
            ChatMessage(content: "I need help with understanding this code", image: NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil), isUser: true),
            ChatMessage(content: "I'll analyze the code you've shared. This appears to be a SwiftUI view implementation with some interesting patterns.", image: nil, isUser: false)
        ]))
    }
    .frame(width: 600, height: 400)
}