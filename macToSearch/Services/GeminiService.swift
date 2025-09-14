//
//  GeminiService.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import SwiftUI

class GeminiService: ObservableObject {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var apiKey: String = ""

    @AppStorage("gemini_api_key") private var storedAPIKey: String = ""
    @AppStorage("gemini_model") private var selectedModel: String = "gemini-1.5-flash"

    init() {
        // Load API key from UserDefaults
        self.apiKey = storedAPIKey
    }
    
    func updateAPIKey(_ key: String) {
        self.apiKey = key
        // Save to UserDefaults
        self.storedAPIKey = key
    }
    
    func searchWithText(_ text: String, context: String = "") async throws -> String {
        // Refresh API key from UserDefaults in case it was updated
        if apiKey.isEmpty {
            apiKey = storedAPIKey
        }

        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        let prompt = buildPrompt(text: text, context: context)
        return try await sendRequest(prompt: prompt)
    }
    
    func searchWithHistory(_ messages: [(content: String, image: NSImage?, isUser: Bool)], newText: String, newImage: NSImage? = nil) async throws -> String {
        // Refresh API key from UserDefaults in case it was updated
        if apiKey.isEmpty {
            apiKey = storedAPIKey
        }

        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        // Build conversation history
        var contents: [[String: Any]] = []
        
        // Add existing messages to history WITHOUT formatting
        for message in messages {
            let role = message.isUser ? "user" : "model"
            var parts: [[String: Any]] = []
            
            // Add text part if not empty - raw content without formatting
            if !message.content.isEmpty {
                parts.append(["text": message.content])
            }
            
            // Add image part if present (only for user messages)
            if let image = message.image, message.isUser {
                if let imageBase64 = try? imageToBase64(image) {
                    parts.append([
                        "inline_data": [
                            "mime_type": "image/jpeg",
                            "data": imageBase64
                        ]
                    ])
                }
            }
            
            if !parts.isEmpty {
                contents.append([
                    "role": role,
                    "parts": parts
                ])
            }
        }
        
        // Add the new message with proper formatting
        var newParts: [[String: Any]] = []
        
        // For the new message, include formatting instructions only if it's the first message
        // Otherwise, just send the raw text to maintain context
        let messageText: String
        if messages.isEmpty {
            // First message - include formatting instructions
            messageText = buildPrompt(text: newText, context: "")
        } else {
            // Subsequent messages - just the text to maintain conversation flow
            messageText = newText
        }
        
        newParts.append(["text": messageText])
        
        // Add new image if present
        if let image = newImage {
            let imageBase64 = try imageToBase64(image)
            newParts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": imageBase64
                ]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": newParts
        ])
        
        // Send request with full conversation history
        return try await sendRequestWithHistory(contents: contents)
    }
    
    private func imageToBase64(_ image: NSImage) throws -> String {
        guard let tiffData = image.tiffRepresentation else {
            throw GeminiError.imageProcessingFailed
        }
        
        guard let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw GeminiError.imageProcessingFailed
        }
        
        let compressionFactor: NSNumber = 0.9
        guard let jpegData = bitmapRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionFactor]
        ) else {
            throw GeminiError.imageProcessingFailed
        }
        
        return jpegData.base64EncodedString()
    }
    
    func searchWithImage(_ image: NSImage, text: String = "What's in this image?") async throws -> String {
        // Refresh API key from UserDefaults in case it was updated
        if apiKey.isEmpty {
            apiKey = storedAPIKey
        }

        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        print("Converting NSImage to JPEG for Gemini...")
        print("Image size: \(image.size)")
        
        // Try to get bitmap representation with better quality
        guard let tiffData = image.tiffRepresentation else {
            print("ERROR: Could not get TIFF representation")
            throw GeminiError.imageProcessingFailed
        }
        
        guard let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            print("ERROR: Could not create bitmap representation")
            throw GeminiError.imageProcessingFailed
        }
        
        print("Bitmap size: \(bitmapRep.pixelsWide) x \(bitmapRep.pixelsHigh)")
        
        // Convert to JPEG with higher quality
        let compressionFactor: NSNumber = 0.9 // Higher quality
        guard let jpegData = bitmapRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionFactor]
        ) else {
            print("ERROR: Could not create JPEG representation")
            throw GeminiError.imageProcessingFailed
        }
        
        print("JPEG data size: \(jpegData.count) bytes")
        
        // Save image locally for debugging (temporary)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("debug_image.jpg")
        try? jpegData.write(to: tempURL)
        print("Debug image saved to: \(tempURL.path)")
        
        let base64Image = jpegData.base64EncodedString()
        print("Base64 string length: \(base64Image.count)")
        
        return try await sendMultimodalRequest(imageBase64: base64Image, text: text)
    }
    
    private func buildPrompt(text: String, context: String) -> String {
        let basePrompt = """
        Please provide a helpful and direct response. Format your answer using markdown:
        - Use **bold** for emphasis on important concepts (never for code)
        - Use `backticks` for code elements, commands, or technical terms when mentioned
        - Use bullet points (* or -) for lists when appropriate
        - Keep your response focused and relevant to the question

        IMPORTANT:
        - Only include code blocks if specifically relevant to the answer
        - Do NOT add example code just for demonstration purposes
        - Focus on answering the user's actual question directly

        """
        
        if !context.isEmpty {
            return basePrompt + """
            Context: \(context)
            
            Question: \(text)
            """
        } else {
            return basePrompt + "Question: \(text)"
        }
    }
    
    private func sendRequest(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/models/\(selectedModel):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,
                "topP": 0.8,
                "topK": 10
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.requestFailed(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        return text
    }
    
    private func sendRequestWithHistory(contents: [[String: Any]]) async throws -> String {
        let url = URL(string: "\(baseURL)/models/\(selectedModel):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,
                "topP": 0.8,
                "topK": 10
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.requestFailed(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        return text
    }
    
    private func sendMultimodalRequest(imageBase64: String, text: String) async throws -> String {
        print("Sending multimodal request to Gemini...")
        let url = URL(string: "\(baseURL)/models/\(selectedModel):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": text],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": imageBase64
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,
                "topP": 0.8,
                "topK": 10
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.requestFailed(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }
        
        return text
    }
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(Int)
    case apiError(String)
    case parseError
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please configure it in Settings or restart the app for initial setup."
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .apiError(let message):
            return "Gemini API error: \(message)"
        case .parseError:
            return "Failed to parse Gemini response"
        case .imageProcessingFailed:
            return "Failed to process image"
        }
    }
}