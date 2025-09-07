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
    
    @AppStorage("gemini_api_key") private var storedAPIKey: String = "AIzaSyAnLZaK-pCQOqlNfvF_WX3S8ZbmXaT7BfA"
    @AppStorage("gemini_model") private var selectedModel: String = "gemini-1.5-flash"
    
    init() {
        self.apiKey = storedAPIKey.isEmpty ? "AIzaSyAnLZaK-pCQOqlNfvF_WX3S8ZbmXaT7BfA" : storedAPIKey
    }
    
    func updateAPIKey(_ key: String) {
        self.apiKey = key
        self.storedAPIKey = key
    }
    
    func searchWithText(_ text: String, context: String = "") async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        let prompt = buildPrompt(text: text, context: context)
        return try await sendRequest(prompt: prompt)
    }
    
    func searchWithImage(_ image: NSImage, text: String = "What's in this image?") async throws -> String {
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
        Please provide a helpful response using proper markdown formatting:
        - Use **bold** for emphasis and important concepts (but NOT for code)
        - Use `backticks` for ALL code elements, commands, functions, or technical terms
        - Never combine bold with backticks - if it's code, use only backticks
        - Use ```language for multi-line code blocks (specify the language)
        - Use * or - for bullet point lists (with a space after)
        - Separate different sections with blank lines
        - Keep explanations clear and well-structured
        
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
            return "Gemini API key is missing. Please add it in Settings."
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