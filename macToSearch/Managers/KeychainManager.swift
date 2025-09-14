//
//  KeychainManager.swift
//  macToSearch
//
//  Created by Assistant on 14/09/2025.
//

import Foundation
import Security

/// Secure credential storage using macOS Keychain
@Observable
final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.macToSearch"
    private let account = "gemini_api_key"

    private init() {}

    /// Save API key to Keychain
    func saveAPIKey(_ apiKey: String) -> Bool {
        guard !apiKey.isEmpty else { return false }

        let data = apiKey.data(using: .utf8)!

        // First try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

        // If item doesn't exist, add it
        if status == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]

            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        return status == errSecSuccess
    }

    /// Retrieve API key from Keychain
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }

        return apiKey
    }

    /// Delete API key from Keychain
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if API key exists in Keychain
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }

    /// Migrate from UserDefaults to Keychain (one-time migration)
    func migrateFromUserDefaults() {
        let userDefaults = UserDefaults.standard

        // Check if we have a key in UserDefaults
        if let oldKey = userDefaults.string(forKey: "gemini_api_key"),
           !oldKey.isEmpty {
            // Save to Keychain
            if saveAPIKey(oldKey) {
                // Clear from UserDefaults after successful migration
                userDefaults.removeObject(forKey: "gemini_api_key")
                print("Successfully migrated API key to Keychain")
            }
        }
    }
}

/// Error types for Keychain operations
enum KeychainError: LocalizedError {
    case saveFailed
    case retrieveFailed
    case deleteFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save API key to Keychain"
        case .retrieveFailed:
            return "Failed to retrieve API key from Keychain"
        case .deleteFailed:
            return "Failed to delete API key from Keychain"
        case .invalidData:
            return "Invalid data format in Keychain"
        }
    }
}