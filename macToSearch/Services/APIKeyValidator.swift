//
//  APIKeyValidator.swift
//  macToSearch
//
//  Created by Assistant on 14/09/2025.
//

import Foundation
import SwiftUI

/// Validates API keys by testing them against the actual service
@Observable
final class APIKeyValidator {
    enum ValidationState {
        case idle
        case validating
        case valid
        case invalid(String)
    }

    var validationState: ValidationState = .idle
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    /// Test if a Gemini API key is valid
    func validateGeminiKey(_ apiKey: String) async -> (isValid: Bool, message: String) {
        guard !apiKey.isEmpty else {
            return (false, "API key cannot be empty")
        }

        // Basic format validation
        guard apiKey.count > 20 else {
            return (false, "API key appears to be too short")
        }

        validationState = .validating

        do {
            // Test the API key with a simple request
            let url = URL(string: "\(baseURL)/models?key=\(apiKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                validationState = .invalid("Invalid response from server")
                return (false, "Could not validate API key")
            }

            switch httpResponse.statusCode {
            case 200:
                validationState = .valid
                return (true, "API key is valid and working")

            case 400:
                validationState = .invalid("Invalid API key format")
                return (false, "API key format is invalid")

            case 401, 403:
                validationState = .invalid("Invalid or unauthorized API key")
                return (false, "API key is invalid or unauthorized")

            case 429:
                validationState = .invalid("Rate limit exceeded")
                return (false, "API rate limit exceeded. Try again later")

            default:
                validationState = .invalid("Unexpected error: \(httpResponse.statusCode)")
                return (false, "Unexpected error occurred. Status: \(httpResponse.statusCode)")
            }

        } catch {
            let errorMessage = "Network error: \(error.localizedDescription)"
            validationState = .invalid(errorMessage)
            return (false, errorMessage)
        }
    }

    /// Quick test to ensure API key can make actual Gemini requests
    func testGeminiConnection(_ apiKey: String) async -> (success: Bool, response: String?) {
        guard !apiKey.isEmpty else {
            return (false, nil)
        }

        do {
            // Simple test prompt
            let testPrompt = "Reply with exactly: 'Connection successful'"
            let url = URL(string: "\(baseURL)/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15

            let requestBody: [String: Any] = [
                "contents": [
                    [
                        "parts": [
                            ["text": testPrompt]
                        ]
                    ]
                ],
                "generationConfig": [
                    "temperature": 0.1,
                    "maxOutputTokens": 50
                ]
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return (false, nil)
            }

            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return (true, text)
            }

            return (false, nil)

        } catch {
            return (false, nil)
        }
    }

    /// Get available Gemini models for the given API key
    func getAvailableModels(_ apiKey: String) async -> [String] {
        guard !apiKey.isEmpty else { return [] }

        do {
            let url = URL(string: "\(baseURL)/models?key=\(apiKey)")!
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {

                let modelNames = models.compactMap { model -> String? in
                    guard let name = model["name"] as? String,
                          let supportedMethods = model["supportedGenerationMethods"] as? [String],
                          supportedMethods.contains("generateContent") else {
                        return nil
                    }
                    // Extract model name from full path (e.g., "models/gemini-1.5-flash" -> "gemini-1.5-flash")
                    return name.replacingOccurrences(of: "models/", with: "")
                }

                return modelNames
            }

        } catch {
            print("Failed to fetch models: \(error)")
        }

        return []
    }
}