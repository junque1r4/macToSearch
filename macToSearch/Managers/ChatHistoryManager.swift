//
//  ChatHistoryManager.swift
//  macToSearch
//
//  Created by Assistant on 09/09/2025.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class ChatHistoryManager: ObservableObject {
    private var modelContext: ModelContext?
    @Published private(set) var currentSession: ChatSession?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Create a new chat session
    func createNewSession(with messages: [MinimalChatMessage] = []) -> ChatSession {
        let chatMessages = messages.map { StoredChatMessage(from: $0) }
        let session = ChatSession(messages: chatMessages)
        session.generateTitle()
        
        if let modelContext = modelContext {
            modelContext.insert(session)
            try? modelContext.save()
        }
        
        currentSession = session
        return session
    }
    
    // Save current messages to active session
    func saveToCurrentSession(messages: [MinimalChatMessage]) {
        // If no current session, create one
        if currentSession == nil {
            currentSession = createNewSession(with: messages)
            return
        }
        
        // Update existing session
        if let session = currentSession {
            session.messages = messages.map { StoredChatMessage(from: $0) }
            session.updatedAt = Date()
            
            // Regenerate title if it's still default
            if session.title == "New Chat" || session.title.starts(with: "Chat at") {
                session.generateTitle()
            }
            
            try? modelContext?.save()
        }
    }
    
    // Load a session
    func loadSession(_ session: ChatSession) -> [MinimalChatMessage] {
        // Deactivate previous session
        if let current = currentSession {
            current.isActive = false
        }
        
        // Activate new session
        session.isActive = true
        currentSession = session
        
        try? modelContext?.save()
        
        // Return messages
        return session.messages.map { $0.toMinimalChatMessage() }
    }
    
    // Clear current session (for new chat)
    func clearCurrentSession() {
        if let current = currentSession {
            current.isActive = false
        }
        currentSession = nil
        try? modelContext?.save()
    }
    
    // Delete a session
    func deleteSession(_ session: ChatSession) {
        if let modelContext = modelContext {
            modelContext.delete(session)
            try? modelContext.save()
        }
        
        if currentSession?.id == session.id {
            currentSession = nil
        }
    }
    
    // Export session as Markdown
    func exportSessionAsMarkdown(_ session: ChatSession) -> String {
        var markdown = "# \(session.title)\n\n"
        markdown += "*Created: \(formatDate(session.createdAt))*\n\n"
        markdown += "---\n\n"
        
        for message in session.messages {
            if message.isUser {
                markdown += "**You:**\n"
            } else {
                markdown += "**Assistant:**\n"
            }
            markdown += "\(message.content)\n\n"
        }
        
        return markdown
    }
    
    // Clean up old sessions (older than days)
    func cleanupOldSessions(olderThanDays days: Int = 30) {
        guard let modelContext = modelContext else { return }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { session in
                session.updatedAt < cutoffDate
            }
        )
        
        if let oldSessions = try? modelContext.fetch(descriptor) {
            for session in oldSessions {
                modelContext.delete(session)
            }
            try? modelContext.save()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}