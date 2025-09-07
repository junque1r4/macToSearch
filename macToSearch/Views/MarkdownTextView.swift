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
            // Single inline code element (shouldn't happen normally but handle it)
            Text(code)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.pink.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pink.opacity(0.08))
                )
            
        case .listItem(let text, let isOrdered):
            HStack(alignment: .top, spacing: 8) {
                Text(isOrdered ? "•" : "•")
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(width: 15)
                
                // Parse inline code within list item
                let parsedContent = parseInlineCode(text)
                if parsedContent.count == 1, case .text(let plainText) = parsedContent[0] {
                    // No inline code, use regular markdown parsing for bold/italic
                    if let attributedString = try? AttributedString(markdown: plainText) {
                        Text(attributedString)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary.opacity(0.9))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(plainText)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary.opacity(0.9))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if case .mixedContent(let parts) = parsedContent.first {
                    // Has inline code, render mixed content
                    let combinedString = createCombinedAttributedString(from: parts)
                    Text(combinedString)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary.opacity(0.9))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Fallback
                    Text(text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary.opacity(0.9))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.leading, 8)
            
        case .paragraph(let parts):
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    switch part {
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
                    case .mixedContent(let subparts):
                        let combinedString = createCombinedAttributedString(from: subparts)
                        Text(combinedString)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary.opacity(0.9))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    default:
                        EmptyView()
                    }
                }
            }
            
        case .mixedContent(let parts):
            // Try using Text concatenation instead of AttributedString
            renderMixedContent(parts)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private func renderMixedContent(_ parts: [ContentSection]) -> some View {
        // Build Text using concatenation
        let combinedText = parts.reduce(Text("")) { result, part in
            switch part {
            case .text(let text):
                return result + Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary.opacity(0.9))
            case .inlineCode(let code):
                // Create an attributed string for the inline code with background
                var codeAttr = AttributedString(code)
                codeAttr.font = .system(size: 13, weight: .regular, design: .monospaced)
                codeAttr.foregroundColor = .pink.opacity(0.9)
                codeAttr.backgroundColor = .pink.opacity(0.08)
                return result + Text(codeAttr)
            default:
                return result
            }
        }
        
        combinedText
    }
    
    private func createCombinedAttributedString(from parts: [ContentSection]) -> AttributedString {
        var result = AttributedString()
        
        for part in parts {
            switch part {
            case .text(let text):
                // Apply font and color directly to the text part
                var textString = AttributedString(text)
                textString.font = .system(size: 15, weight: .regular)
                textString.foregroundColor = .primary.opacity(0.9)
                result.append(textString)
            case .inlineCode(let code):
                var codeString = AttributedString(code)
                codeString.font = .system(size: 13, weight: .regular, design: .monospaced)
                codeString.foregroundColor = .pink.opacity(0.9)
                codeString.backgroundColor = .pink.opacity(0.08)
                result.append(codeString)
            default:
                break
            }
        }
        
        return result
    }
    
    private func parseContent(_ content: String) -> [ContentSection] {
        var sections: [ContentSection] = []
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var currentParagraph: [String] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for code block start
            if line.starts(with: "```") {
                // Save any accumulated paragraph
                if !currentParagraph.isEmpty {
                    let paragraphText = currentParagraph.joined(separator: "\n")
                    sections.append(contentsOf: parseParagraph(paragraphText))
                    currentParagraph = []
                }
                
                // Extract language identifier
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                
                // Collect code lines until closing ```
                while i < lines.count && !lines[i].starts(with: "```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                
                if !codeLines.isEmpty {
                    let code = codeLines.joined(separator: "\n")
                    sections.append(.codeBlock(code, language.isEmpty ? nil : language))
                }
            }
            // Check for list items (starts with * or - followed by space)
            else if (trimmedLine.starts(with: "* ") || trimmedLine.starts(with: "- ")) && trimmedLine.count > 2 {
                // Save any accumulated paragraph
                if !currentParagraph.isEmpty {
                    let paragraphText = currentParagraph.joined(separator: "\n")
                    sections.append(contentsOf: parseParagraph(paragraphText))
                    currentParagraph = []
                }
                
                // Extract list item text (remove the bullet and space)
                let itemText = String(trimmedLine.dropFirst(2))
                sections.append(.listItem(itemText, isOrdered: false))
            }
            // Check for empty line (paragraph separator)
            else if trimmedLine.isEmpty {
                // Save current paragraph if exists
                if !currentParagraph.isEmpty {
                    let paragraphText = currentParagraph.joined(separator: "\n")
                    sections.append(contentsOf: parseParagraph(paragraphText))
                    currentParagraph = []
                }
            }
            // Regular text line
            else {
                currentParagraph.append(line)
            }
            
            i += 1
        }
        
        // Add any remaining paragraph
        if !currentParagraph.isEmpty {
            let paragraphText = currentParagraph.joined(separator: "\n")
            sections.append(contentsOf: parseParagraph(paragraphText))
        }
        
        return sections
    }
    
    private func parseParagraph(_ text: String) -> [ContentSection] {
        // Parse inline elements within a paragraph
        return parseInlineCode(text)
    }
    
    private func parseInlineCode(_ text: String) -> [ContentSection] {
        var parts: [ContentSection] = []
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
                
                // Check if we need to add space before the code
                // Check if currentText ends with alphanumeric (text accumulated so far)
                if !currentText.isEmpty {
                    if let lastChar = currentText.last, (lastChar.isLetter || lastChar.isNumber) {
                        // Add space to current text if it doesn't already end with one
                        if !currentText.hasSuffix(" ") {
                            currentText.append(" ") // Regular space
                        }
                    }
                }
                
                // Save accumulated text
                if !currentText.isEmpty {
                    parts.append(.text(currentText))
                    currentText = ""
                }
                
                // Find closing backtick
                var j = text.index(after: i)
                while j < text.endIndex && text[j] != "`" {
                    j = text.index(after: j)
                }
                
                if j < text.endIndex {
                    let code = String(text[text.index(after: i)..<j])
                    parts.append(.inlineCode(code))
                    
                    // Move past the closing backtick
                    i = text.index(after: j)
                    
                    // Check if character after closing ` needs spacing
                    if i < text.endIndex {
                        let nextChar = text[i]
                        if nextChar.isLetter || nextChar.isNumber {
                            // Start next text with regular space
                            currentText = " "
                        }
                        // Don't skip spaces - let them be added naturally
                    }
                    continue
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
            parts.append(.text(currentText))
        }
        
        // If we have mixed content (text + inline code), wrap it
        if parts.count > 1 {
            return [.mixedContent(parts)]
        } else if parts.count == 1 {
            return parts
        } else {
            return [.text(text)]
        }
    }
}

enum ContentSection: Equatable {
    case text(String)
    case codeBlock(String, String?)
    case mixedContent([ContentSection])
    case inlineCode(String)
    case listItem(String, isOrdered: Bool)
    case paragraph([ContentSection])
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

// Extension for testing (internal visibility)
extension MarkdownTextView {
    static func parseInlineCodeForTesting(_ text: String) -> [ContentSection] {
        let view = MarkdownTextView(content: "")
        return view.parseInlineCode(text)
    }
    
    static func renderSectionsAsText(_ sections: [ContentSection]) -> String {
        var result = ""
        for section in sections {
            switch section {
            case .text(let text):
                result += text
            case .inlineCode(let code):
                result += "`\(code)`"
            case .mixedContent(let parts):
                result += renderSectionsAsText(parts)
            default:
                break
            }
        }
        return result
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