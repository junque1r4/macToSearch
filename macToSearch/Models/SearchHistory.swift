//
//  SearchHistory.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class SearchHistory {
    var id: UUID
    var timestamp: Date
    var searchType: SearchType
    var query: String
    var response: String
    var imageData: Data?
    var textContent: String?
    var aiProvider: String
    
    enum SearchType: String, Codable {
        case screenshot = "screenshot"
        case clipboard = "clipboard"
        case text = "text"
    }
    
    init(searchType: SearchType, query: String, response: String, imageData: Data? = nil, textContent: String? = nil, aiProvider: String = "OpenAI") {
        self.id = UUID()
        self.timestamp = Date()
        self.searchType = searchType
        self.query = query
        self.response = response
        self.imageData = imageData
        self.textContent = textContent
        self.aiProvider = aiProvider
    }
}