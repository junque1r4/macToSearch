//
//  MarkdownTextView.swift
//  macToSearch
//
//  Created by Assistant on 07/09/2025.
//

import SwiftUI

struct MarkdownTextView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let sections = parseContent(content)
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                renderSection(section)
            }
        }
    }
    
    @ViewBuilder
    private func renderSection(_ section: ContentSection) -> some View {
        switch section {
        case .text(let text):
            if let attributedString = try? AttributedString(markdown: text) {
                Text(attributedString)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary.opacity(0.9))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary.opacity(0.9))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
        case .codeBlock(let code, let language):
            CodeBlockView(code: code, language: language)
                .padding(.vertical, 4)
            
        case .inlineCode(let code):
            Text(code)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.pink.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pink.opacity(0.08))
                )
        }
    }
    
    private func parseContent(_ content: String) -> [ContentSection] {
        var sections: [ContentSection] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var currentText = ""
        var i = 0
        
        while i < lines.count {
            let line = String(lines[i])
            
            // Check for code block start
            if line.starts(with: "```") {
                // Save any accumulated text
                if !currentText.isEmpty {
                    sections.append(contentsOf: parseInlineCode(currentText))
                    currentText = ""
                }
                
                // Extract language identifier
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                
                // Collect code lines until closing ```
                while i < lines.count && !lines[i].starts(with: "```") {
                    codeLines.append(String(lines[i]))
                    i += 1
                }
                
                if !codeLines.isEmpty {
                    let code = codeLines.joined(separator: "\n")
                    sections.append(.codeBlock(code, language.isEmpty ? nil : language))
                }
            } else {
                // Accumulate regular text
                if !currentText.isEmpty {
                    currentText += "\n"
                }
                currentText += line
            }
            
            i += 1
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            sections.append(contentsOf: parseInlineCode(currentText))
        }
        
        return sections
    }
    
    private func parseInlineCode(_ text: String) -> [ContentSection] {
        var sections: [ContentSection] = []
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            if text[i] == "`" && i < text.index(before: text.endIndex) {
                // Check if it's a code block marker (```)
                let nextIndex = text.index(after: i)
                if nextIndex < text.endIndex && text[nextIndex] == "`" {
                    let nextNextIndex = text.index(after: nextIndex)
                    if nextNextIndex < text.endIndex && text[nextNextIndex] == "`" {
                        // It's a code block marker, treat as regular text
                        currentText.append(text[i])
                        i = text.index(after: i)
                        continue
                    }
                }
                
                // Save accumulated text
                if !currentText.isEmpty {
                    sections.append(.text(currentText))
                    currentText = ""
                }
                
                // Find closing backtick
                var j = text.index(after: i)
                while j < text.endIndex && text[j] != "`" {
                    j = text.index(after: j)
                }
                
                if j < text.endIndex {
                    let code = String(text[text.index(after: i)..<j])
                    sections.append(.inlineCode(code))
                    i = j
                } else {
                    currentText.append(text[i])
                }
            } else {
                currentText.append(text[i])
            }
            
            if i < text.endIndex {
                i = text.index(after: i)
            }
        }
        
        // Add remaining text
        if !currentText.isEmpty {
            sections.append(.text(currentText))
        }
        
        return sections.isEmpty ? [.text(text)] : sections
    }
}

enum ContentSection {
    case text(String)
    case codeBlock(String, String?)
    case inlineCode(String)
}

// Simple code block view
struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            if language != nil || !code.isEmpty {
                HStack {
                    if let lang = language {
                        Text(lang)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: copyCode) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04))
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.85))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MarkdownTextView(content: """
        **Funções em Rust:**
        
        Aqui está um exemplo de função simples:
        
        ```rust
        fn greet() {
            println!("Olá, mundo!");
        }
        ```
        
        E aqui temos código inline: `println!()` é usado para imprimir.
        """)
        .frame(width: 400)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}