//
//  AppState.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isCapturing = false
    @Published var showSearchOverlay = false
    @Published var showMainWindow = false
    @Published var lastCapturedImage: NSImage?
    @Published var lastExtractedText: String = ""
    @Published var searchResults: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @AppStorage("gemini_api_key") var geminiAPIKey: String = "AIzaSyAnLZaK-pCQOqlNfvF_WX3S8ZbmXaT7BfA"
    @AppStorage("gemini_model") var preferredModel: String = "gemini-1.5-flash"
    @AppStorage("use_local_ai") var useLocalAI: Bool = false
    
    func reset() {
        isCapturing = false
        showSearchOverlay = false
        lastCapturedImage = nil
        lastExtractedText = ""
        searchResults = ""
        isLoading = false
        errorMessage = nil
    }
}