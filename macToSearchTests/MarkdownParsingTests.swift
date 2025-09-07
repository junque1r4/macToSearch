//
//  MarkdownParsingTests.swift
//  macToSearchTests
//
//  Created by Assistant on 07/09/2025.
//

import Testing
import SwiftUI
@testable import macToSearch

struct MarkdownParsingTests {
    
    @Test("Inline code should have spaces before and after when surrounded by alphanumeric characters")
    func testInlineCodeSpacingWithAlphanumeric() {
        // Test case 1: "the`fn`keyword" should become "the `fn` keyword"
        let input1 = "Rust functions are defined using the`fn`keyword, followed by"
        let sections1 = MarkdownTextView.parseInlineCodeForTesting(input1)
        let result1 = MarkdownTextView.renderSectionsAsText(sections1)
        // Now expecting regular spaces
        #expect(result1 == "Rust functions are defined using the `fn` keyword, followed by")
        
        // Test case 2: "not`()`the" should become "not `()` the"
        let input2 = "if not`()`the unit type"
        let sections2 = MarkdownTextView.parseInlineCodeForTesting(input2)
        let result2 = MarkdownTextView.renderSectionsAsText(sections2)
        #expect(result2 == "if not `()` the unit type")
        
        // Test case 3: "braces`{}`." should become "braces `{}`."
        let input3 = "enclosed in curly braces`{}`."
        let sections3 = MarkdownTextView.parseInlineCodeForTesting(input3)
        let result3 = MarkdownTextView.renderSectionsAsText(sections3)
        #expect(result3 == "enclosed in curly braces `{}`.")
    }
    
    @Test("Inline code with existing spaces should be preserved")
    func testInlineCodeWithExistingSpaces() {
        // When spaces already exist, they should be preserved
        let input = "the `fn` keyword is used"
        let sections = MarkdownTextView.parseInlineCodeForTesting(input)
        let result = MarkdownTextView.renderSectionsAsText(sections)
        #expect(result == "the `fn` keyword is used")
    }
    
    @Test("Multiple inline codes in same text")
    func testMultipleInlineCodes() {
        let input = "Use`fn`for functions and`let`for variables"
        let sections = MarkdownTextView.parseInlineCodeForTesting(input)
        let result = MarkdownTextView.renderSectionsAsText(sections)
        #expect(result == "Use `fn` for functions and `let` for variables")
    }
    
    @Test("Inline code at start and end of text")
    func testInlineCodeAtBoundaries() {
        // Code at the start
        let input1 = "`fn`is a keyword"
        let sections1 = MarkdownTextView.parseInlineCodeForTesting(input1)
        let result1 = MarkdownTextView.renderSectionsAsText(sections1)
        #expect(result1 == "`fn` is a keyword")
        
        // Code at the end
        let input2 = "the keyword is`fn`"
        let sections2 = MarkdownTextView.parseInlineCodeForTesting(input2)
        let result2 = MarkdownTextView.renderSectionsAsText(sections2)
        #expect(result2 == "the keyword is `fn`")
    }
    
    @Test("Real world example from Gemini response")
    func testRealWorldGeminiResponse() {
        let input = "Rust functions are defined using the`fn`keyword, followed by the function name, parameters (if any), a return type (if not`()`the unit type, indicating no return value), and the function body enclosed in curly braces`{}`."
        
        let sections = MarkdownTextView.parseInlineCodeForTesting(input)
        let result = MarkdownTextView.renderSectionsAsText(sections)
        
        let expected = "Rust functions are defined using the `fn` keyword, followed by the function name, parameters (if any), a return type (if not `()` the unit type, indicating no return value), and the function body enclosed in curly braces `{}`."
        
        #expect(result == expected)
    }
    
    @Test("Test AttributedString combination")
    func testAttributedStringCombination() {
        // Test if the problem is in AttributedString combination
        let input = "the`fn`keyword"
        let sections = MarkdownTextView.parseInlineCodeForTesting(input)
        
        // Verify sections are correct
        let result = MarkdownTextView.renderSectionsAsText(sections)
        #expect(result == "the `fn` keyword")
        
        // Now test if the issue is when rendering AttributedString
        // This simulates what happens in createCombinedAttributedString
        var attributedResult = AttributedString()
        
        if case .mixedContent(let parts) = sections[0] {
            for part in parts {
                switch part {
                case .text(let text):
                    attributedResult.append(AttributedString(text))
                case .inlineCode(let code):
                    var codeString = AttributedString(code)
                    codeString.font = .system(size: 13, weight: .regular, design: .monospaced)
                    attributedResult.append(codeString)
                default:
                    break
                }
            }
        }
        
        // Check the final string value
        let finalString = String(attributedResult.characters)
        print("Final AttributedString: '\(finalString)'")
        #expect(finalString == "the fn keyword")
    }
    
    @Test("Debug sections structure")
    func testSectionsStructure() {
        let input = "using the`fn`keyword"
        let sections = MarkdownTextView.parseInlineCodeForTesting(input)
        
        // Check the exact sections returned
        #expect(sections.count == 1)
        
        if case .mixedContent(let parts) = sections[0] {
            #expect(parts.count == 3)
            
            // First part should be "using the "
            if case .text(let text1) = parts[0] {
                #expect(text1 == "using the ")
            } else {
                Issue.record("First part is not text")
            }
            
            // Second part should be inline code "fn"
            if case .inlineCode(let code) = parts[1] {
                #expect(code == "fn")
            } else {
                Issue.record("Second part is not inline code")
            }
            
            // Third part should be " keyword"
            if case .text(let text2) = parts[2] {
                #expect(text2 == " keyword")
            } else {
                Issue.record("Third part is not text")
            }
        } else {
            Issue.record("Not mixed content")
        }
    }
}