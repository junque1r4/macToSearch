//
//  CompactChatView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct CompactChatView: View {
    @Binding var messages: [MinimalChatMessage]
    @State private var scrollToBottom = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        CompactMessageBubble(message: message)
                            .id(index)
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _ in
                withAnimation(.spring(response: 0.3)) {
                    proxy.scrollTo(messages.count - 1, anchor: .bottom)
                }
            }
        }
    }
}

struct CompactMessageBubble: View {
    let message: MinimalChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    // Image if attached
                    if let image = message.image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 120)
                            .cornerRadius(10)
                    }
                    
                    // Text content
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.system(size: 13))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            message.isUser ?
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(NSColor.controlBackgroundColor),
                                    Color(NSColor.controlBackgroundColor).opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    message.isUser ? 
                                    Color.clear : 
                                    Color.primary.opacity(0.05),
                                    lineWidth: 0.5
                                )
                        )
                )
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MinimalChatMessage is defined in MinimalChatBubble.swift

#Preview {
    CompactChatView(messages: .constant([
        MinimalChatMessage(
            content: "What's the weather like today?",
            image: nil,
            isUser: true
        ),
        MinimalChatMessage(
            content: "I'll help you check the weather. Based on current conditions, it's a partly cloudy day with temperatures around 72°F (22°C). There's a slight breeze from the west at about 10 mph.",
            image: nil,
            isUser: false
        ),
        MinimalChatMessage(
            content: "What's in this image?",
            image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
            isUser: true
        ),
        MinimalChatMessage(
            content: "This appears to be a placeholder image icon. In a real scenario, I would analyze the actual image content and provide details about what I see.",
            image: nil,
            isUser: false
        )
    ]))
    .frame(width: 400, height: 500)
    .background(Color.gray.opacity(0.1))
}