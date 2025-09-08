//
//  ChatSession.swift
//  macToSearch
//
//  Created by Assistant on 09/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ChatSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messagesData: Data  // Encoded array of ChatMessage
    var isActive: Bool
    var preview: String  // First few words for preview
    
    // Computed property to get/set messages
    var messages: [StoredChatMessage] {
        get {
            guard let decoded = try? JSONDecoder().decode([StoredChatMessage].self, from: messagesData) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                messagesData = encoded
                updatedAt = Date()
                // Update preview with last user message or first message
                if let lastUserMessage = newValue.last(where: { $0.isUser }) {
                    preview = String(lastUserMessage.content.prefix(100))
                } else if let firstMessage = newValue.first {
                    preview = String(firstMessage.content.prefix(100))
                }
            }
        }
    }
    
    init(title: String = "New Chat", messages: [StoredChatMessage] = []) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        self.preview = ""
        
        // Encode messages
        if let encoded = try? JSONEncoder().encode(messages) {
            self.messagesData = encoded
        } else {
            self.messagesData = Data()
        }
        
        // Set preview
        if let firstMessage = messages.first {
            self.preview = String(firstMessage.content.prefix(100))
        }
    }
    
    // Generate smart title from first message
    func generateTitle() {
        guard !messages.isEmpty else { return }
        
        if let firstUserMessage = messages.first(where: { $0.isUser }) {
            // Extract meaningful title from first user message
            let content = firstUserMessage.content
            
            // Remove common prefixes
            let cleanedContent = content
                .replacingOccurrences(of: "What's in this image?", with: "Image Analysis")
                .replacingOccurrences(of: "What's in these images?", with: "Multiple Images")
            
            // Take first sentence or first 50 characters
            if let firstSentence = cleanedContent.components(separatedBy: CharacterSet(charactersIn: ".?!")).first,
               !firstSentence.isEmpty {
                title = String(firstSentence.prefix(50))
            } else {
                title = String(cleanedContent.prefix(50))
            }
            
            // Clean up title
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty {
                title = "Chat at \(formatDate(createdAt))"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// Codable structure for messages
struct StoredChatMessage: Codable, Identifiable {
    let id: UUID
    let content: String
    let imagesData: [Data]?  // Encoded NSImage data
    let isUser: Bool
    let timestamp: Date
    
    init(from minimalMessage: MinimalChatMessage) {
        self.id = minimalMessage.id
        self.content = minimalMessage.content
        self.isUser = minimalMessage.isUser
        self.timestamp = minimalMessage.timestamp
        
        // Convert NSImages to Data
        if let images = minimalMessage.images {
            self.imagesData = images.compactMap { image in
                image.tiffRepresentation?.compressed
            }
        } else {
            self.imagesData = nil
        }
    }
    
    // Convert back to MinimalChatMessage
    func toMinimalChatMessage() -> MinimalChatMessage {
        let images = imagesData?.compactMap { data in
            NSImage(data: data)
        }
        
        return MinimalChatMessage(
            content: content,
            images: images,
            isUser: isUser
        )
    }
}

// Extension for Data compression
extension Data {
    var compressed: Data? {
        try? (self as NSData).compressed(using: .lzfse) as Data
    }
    
    var decompressed: Data? {
        try? (self as NSData).decompressed(using: .lzfse) as Data
    }
}