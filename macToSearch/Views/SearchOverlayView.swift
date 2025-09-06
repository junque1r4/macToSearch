//
//  SearchOverlayView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct SearchOverlayView: View {
    @EnvironmentObject var appState: AppState
    @State private var startPoint: CGPoint = .zero
    @State private var endPoint: CGPoint = .zero
    @State private var isSelecting = false
    @State private var selectionType: SelectionType = .rectangle
    
    enum SelectionType {
        case rectangle
        case circle
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Selection overlay
                if isSelecting {
                    selectionOverlay
                }
                
                // Instructions
                VStack {
                    Spacer()
                    
                    HStack {
                        Text("Click and drag to select area")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("• ESC to cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(radius: 10)
                    )
                    .padding(.bottom, 50)
                }
                
                // Selection type toggle
                VStack {
                    HStack(spacing: 12) {
                        SelectionTypeButton(
                            type: .rectangle,
                            currentType: $selectionType,
                            icon: "rectangle.dashed"
                        )
                        
                        SelectionTypeButton(
                            type: .circle,
                            currentType: $selectionType,
                            icon: "circle.dashed"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .shadow(radius: 10)
                    )
                    .padding(.top, 50)
                    
                    Spacer()
                }
            }
            .onAppear {
                NSCursor.crosshair.set()
            }
            .onDisappear {
                NSCursor.arrow.set()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isSelecting {
                            startPoint = value.startLocation
                            isSelecting = true
                        }
                        endPoint = value.location
                    }
                    .onEnded { value in
                        captureSelection()
                    }
            )
            .onExitCommand {
                cancelSelection()
            }
        }
    }
    
    @ViewBuilder
    var selectionOverlay: some View {
        let rect = normalizedRect
        
        if selectionType == .rectangle {
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .background(Color.accentColor.opacity(0.1))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        } else {
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
                .background(Color.accentColor.opacity(0.1))
                .frame(width: rect.width, height: rect.width)
                .position(x: rect.midX, y: rect.midY)
        }
    }
    
    var normalizedRect: CGRect {
        let x = min(startPoint.x, endPoint.x)
        let y = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func captureSelection() {
        Task {
            let screenCapture = ScreenCaptureManagerV2.shared
            
            // Calculate the selection rect
            let minX = min(startPoint.x, endPoint.x)
            let minY = min(startPoint.y, endPoint.y)
            let width = abs(endPoint.x - startPoint.x)
            let height = abs(endPoint.y - startPoint.y)
            let selectionRect = CGRect(x: minX, y: minY, width: width, height: height)
            
            // Try to capture the selected area
            if let image = await screenCapture.captureArea(selectionRect) {
                await MainActor.run {
                    appState.lastCapturedImage = image
                    appState.showSearchOverlay = false
                    
                    // Process the captured image
                    Task {
                        await processCapture(image)
                    }
                }
            } else {
                // Fallback: capture full screen and crop
                do {
                    if let fullImage = try await screenCapture.captureScreenDirect() {
                        // Crop the image to selection
                        let croppedImage = cropImage(fullImage, to: selectionRect)
                        
                        await MainActor.run {
                            appState.lastCapturedImage = croppedImage
                            appState.showSearchOverlay = false
                            
                            // Process the captured image
                            Task {
                                await processCapture(croppedImage)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        appState.errorMessage = "Failed to capture selection"
                        appState.showSearchOverlay = false
                    }
                }
            }
        }
    }
    
    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }
        
        let scale = CGFloat(cgImage.width) / image.size.width
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: (image.size.height - rect.origin.y - rect.height) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return image
        }
        
        return NSImage(cgImage: croppedCGImage, size: rect.size)
    }
    
    private func processCapture(_ image: NSImage) async {
        let ocrManager = OCRManager()
        let geminiService = GeminiService()
        
        appState.isLoading = true
        
        do {
            // Extract text
            let extractedText = try await ocrManager.extractText(from: image)
            appState.lastExtractedText = extractedText
            
            // Search with Gemini
            let result = try await geminiService.searchWithImage(
                image,
                text: extractedText.isEmpty ? "What's in this image?" : extractedText
            )
            
            await MainActor.run {
                appState.searchResults = result
                appState.isLoading = false
                appState.showMainWindow = true
            }
        } catch {
            await MainActor.run {
                appState.errorMessage = error.localizedDescription
                appState.isLoading = false
            }
        }
    }
    
    private func cancelSelection() {
        appState.showSearchOverlay = false
        appState.reset()
    }
}

struct SelectionTypeButton: View {
    let type: SearchOverlayView.SelectionType
    @Binding var currentType: SearchOverlayView.SelectionType
    let icon: String
    
    var isSelected: Bool {
        currentType == type
    }
    
    var body: some View {
        Button(action: {
            currentType = type
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchOverlayView()
        .environmentObject(AppState())
}