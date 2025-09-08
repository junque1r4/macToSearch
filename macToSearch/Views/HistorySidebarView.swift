//
//  HistorySidebarView.swift
//  macToSearch
//
//  Created by Assistant on 09/09/2025.
//

import SwiftUI
import SwiftData

struct HistorySidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]
    @Binding var selectedSession: ChatSession?
    @Binding var currentMessages: [MinimalChatMessage]
    let onNewChat: () -> Void
    
    @State private var hoveredSession: ChatSession?
    @State private var searchText = ""
    @State private var gradientRotation = 0.0
    
    var filteredSessions: [ChatSession] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(searchText) ||
            session.preview.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Group sessions by date
    var groupedSessions: [(String, [ChatSession])] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [(String, [ChatSession])] = []
        var todaySessions: [ChatSession] = []
        var yesterdaySessions: [ChatSession] = []
        var weekSessions: [ChatSession] = []
        var olderSessions: [ChatSession] = []
        
        for session in filteredSessions {
            if calendar.isDateInToday(session.updatedAt) {
                todaySessions.append(session)
            } else if calendar.isDateInYesterday(session.updatedAt) {
                yesterdaySessions.append(session)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      session.updatedAt > weekAgo {
                weekSessions.append(session)
            } else {
                olderSessions.append(session)
            }
        }
        
        if !todaySessions.isEmpty {
            groups.append(("Today", todaySessions))
        }
        if !yesterdaySessions.isEmpty {
            groups.append(("Yesterday", yesterdaySessions))
        }
        if !weekSessions.isEmpty {
            groups.append(("This Week", weekSessions))
        }
        if !olderSessions.isEmpty {
            groups.append(("Older", olderSessions))
        }
        
        return groups
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Text("Chat History")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onNewChat) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("New Chat")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    TextField("Search chats...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
            
            Divider()
                .opacity(0.3)
            
            // Sessions list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(groupedSessions, id: \.0) { group, sessions in
                        VStack(alignment: .leading, spacing: 8) {
                            // Date section header
                            Text(group)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.7))
                                .padding(.horizontal, 16)
                            
                            // Sessions in this group
                            ForEach(sessions) { session in
                                ChatSessionRow(
                                    session: session,
                                    isSelected: selectedSession?.id == session.id,
                                    isHovered: hoveredSession?.id == session.id,
                                    gradientRotation: gradientRotation
                                )
                                .onTapGesture {
                                    selectSession(session)
                                }
                                .onHover { hovering in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        hoveredSession = hovering ? session : nil
                                    }
                                }
                                .contextMenu {
                                    Button("Delete") {
                                        deleteSession(session)
                                    }
                                    Button("Rename") {
                                        // TODO: Implement rename
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280)
        .background {
            ZStack {
                // Glassmorphic background
                GlassmorphismBackground()
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            // Start gradient animation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
    
    private func selectSession(_ session: ChatSession) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedSession = session
            // Convert stored messages to MinimalChatMessage
            currentMessages = session.messages.map { $0.toMinimalChatMessage() }
        }
    }
    
    private func deleteSession(_ session: ChatSession) {
        withAnimation {
            modelContext.delete(session)
            if selectedSession?.id == session.id {
                selectedSession = nil
                currentMessages = []
            }
        }
    }
}

// MARK: - Chat Session Row
struct ChatSessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let isHovered: Bool
    let gradientRotation: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "message.fill")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .blue : .secondary.opacity(0.6))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(session.preview)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
                
                Text(formatTime(session.updatedAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            } else if isHovered {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 1
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 5)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}