//
//  DrawingOverlayView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI
import Vision

struct DrawingOverlayView: View {
    @EnvironmentObject var appState: AppState
    @State private var backgroundImage: NSImage?
    @State private var paths: [DrawingPath] = []
    @State private var currentPath = DrawingPath()
    @State private var isDrawing = false
    @State private var detectedShape: DetectedShape = .unknown
    @State private var showShapeHint = false
    @State private var selectedRegion: CGRect?
    @State private var isProcessing = false
    
    let screenCapture = ScreenCaptureManagerV2.shared
    let ocrManager = OCRManager()
    let geminiService = GeminiService()
    let elementDetector = ElementDetector()
    
    @State private var detectedElements: [ElementDetector.DetectedElement] = []
    @State private var highlightedElement: ElementDetector.DetectedElement?
    
    // Screenshot passed from AppDelegate
    let screenshot: NSImage?
    
    init(screenshot: NSImage? = nil) {
        self.screenshot = screenshot
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background screenshot - display at 1:1 scale (no scaling)
                if let image = backgroundImage {
                    Image(nsImage: image)
                        // Don't use .resizable() or .scaledToFit() - keep original size
                        .frame(width: image.size.width, height: image.size.height)
                        // Remove opacity to show apps without transparency
                } else {
                    Color.black.opacity(0.3)
                }
                
                // Drawing canvas
                Canvas { context, size in
                    // Draw completed paths
                    for path in paths {
                        context.stroke(
                            path.path,
                            with: .color(path.strokeColor),
                            lineWidth: path.lineWidth
                        )
                    }
                    
                    // Draw current path
                    if isDrawing {
                        context.stroke(
                            currentPath.path,
                            with: .color(currentPath.strokeColor),
                            lineWidth: currentPath.lineWidth
                        )
                    }
                    
                    // Highlight selected region with better visibility
                    if let region = selectedRegion {
                        // Draw a solid background first
                        context.fill(
                            Path(roundedRect: region, cornerRadius: 8),
                            with: .color(.green.opacity(0.15))
                        )
                        
                        // Draw animated dashed border
                        context.stroke(
                            Path(roundedRect: region, cornerRadius: 8),
                            with: .color(.green),
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4], dashPhase: 0)
                        )
                        
                        // Draw corner handles for better visibility
                        let handleSize: CGFloat = 8
                        let handleColor = Color.green
                        
                        // Top-left corner
                        context.fill(
                            Path(ellipseIn: CGRect(x: region.minX - handleSize/2, y: region.minY - handleSize/2, width: handleSize, height: handleSize)),
                            with: .color(handleColor)
                        )
                        
                        // Top-right corner
                        context.fill(
                            Path(ellipseIn: CGRect(x: region.maxX - handleSize/2, y: region.minY - handleSize/2, width: handleSize, height: handleSize)),
                            with: .color(handleColor)
                        )
                        
                        // Bottom-left corner
                        context.fill(
                            Path(ellipseIn: CGRect(x: region.minX - handleSize/2, y: region.maxY - handleSize/2, width: handleSize, height: handleSize)),
                            with: .color(handleColor)
                        )
                        
                        // Bottom-right corner
                        context.fill(
                            Path(ellipseIn: CGRect(x: region.maxX - handleSize/2, y: region.maxY - handleSize/2, width: handleSize, height: handleSize)),
                            with: .color(handleColor)
                        )
                    }
                    
                    // Highlight detected element on hover
                    if let element = highlightedElement {
                        context.stroke(
                            Path(roundedRect: element.boundingBox, cornerRadius: 4),
                            with: .color(.blue),
                            style: StrokeStyle(lineWidth: 2, dash: [3, 3])
                        )
                    }
                }
                
                // UI Controls
                VStack {
                    // Top toolbar
                    HStack {
                        // Drawing tools
                        HStack(spacing: 12) {
                            Button(action: clearDrawing) {
                                Label("Clear", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: undoLastPath) {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .buttonStyle(.bordered)
                            .disabled(paths.isEmpty)
                            
                            if showShapeHint {
                                Text("Detected: \(detectedShape.description)")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: performSearch) {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(paths.isEmpty && selectedRegion == nil || isProcessing)
                            .keyboardShortcut(.return, modifiers: [])
                            
                            Button(action: cancelDrawing) {
                                Label("Cancel", systemImage: "xmark")
                            }
                            .buttonStyle(.bordered)
                            .keyboardShortcut(.escape, modifiers: [])
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .cornerRadius(12)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Draw to select • Click to select element")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 16) {
                            Label("Circle areas", systemImage: "scribble")
                            Label("ESC to cancel", systemImage: "escape")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
                    .cornerRadius(12)
                    .padding(.bottom, 30)
                }
                
                // Loading overlay
                if isProcessing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing selection...")
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .onAppear {
                // Use the screenshot passed from AppDelegate
                if let screenshot = screenshot {
                    backgroundImage = screenshot
                    
                    // No need to calculate display properties - using 1:1 display
                    print("Screenshot loaded at 1:1 scale: \(screenshot.size)")
                    
                    // Detect elements in background
                    Task {
                        if let elements = try? await elementDetector.detectElements(in: screenshot) {
                            await MainActor.run {
                                self.detectedElements = elements
                            }
                        }
                    }
                } else {
                    // Fallback: capture if no screenshot was passed
                    captureScreen()
                }
            }
            .gesture(drawingGesture)
            .onTapGesture { location in
                handleTap(at: location)
            }
            .onExitCommand {
                cancelDrawing()
            }
        }
    }
    
    var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDrawing {
                    isDrawing = true
                    currentPath = DrawingPath()
                }
                currentPath.addPoint(value.location)
                
                // Check for shape detection
                if currentPath.points.count > 10 {
                    let shape = currentPath.detectShape()
                    if shape != .unknown && shape != .line {
                        detectedShape = shape
                        showShapeHint = true
                    }
                }
            }
            .onEnded { value in
                currentPath.complete()
                
                // Process the completed path
                if currentPath.points.count > 3 {
                    paths.append(currentPath)
                    
                    // Auto-detect selection region
                    if let bbox = currentPath.boundingBox() {
                        selectedRegion = bbox
                        print("Selected region set from drawing: \(bbox)")
                        print("Region size: \(bbox.width) x \(bbox.height)")
                        
                        // Show visual feedback
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showShapeHint = true
                        }
                    } else {
                        print("WARNING: Could not create bounding box from path")
                    }
                } else {
                    print("Path too short: only \(currentPath.points.count) points")
                }
                
                currentPath = DrawingPath()
                isDrawing = false
                
                // Hide shape hint after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showShapeHint = false
                }
            }
    }
    
    private func captureScreen() {
        // This is now only a fallback - should not normally be called
        print("Warning: captureScreen fallback called - screenshot should have been passed from AppDelegate")
        
        Task {
            // Try CGDisplay method first as it's less likely to trigger permissions
            if let fallbackImage = screenCapture.captureWithCGDisplay() {
                let elements = try? await elementDetector.detectElements(in: fallbackImage)
                
                await MainActor.run {
                    self.backgroundImage = fallbackImage
                    self.detectedElements = elements ?? []
                }
            } else {
                // Last resort: try direct capture
                do {
                    if let screenshot = try await screenCapture.captureScreenDirect() {
                        let elements = try? await elementDetector.detectElements(in: screenshot)
                        
                        await MainActor.run {
                            self.backgroundImage = screenshot
                            self.detectedElements = elements ?? []
                        }
                    }
                } catch {
                    print("All capture methods failed: \(error)")
                    // Show a semi-transparent background as last resort
                    await MainActor.run {
                        self.backgroundImage = nil
                    }
                }
            }
        }
    }
    
    private func handleTap(at location: CGPoint) {
        // Smart element detection at tap location
        Task {
            await detectElementAt(location)
        }
    }
    
    private func detectElementAt(_ point: CGPoint) async {
        guard let image = backgroundImage else { return }
        
        // Find element at tap location
        if let element = elementDetector.findElementAt(point: point, in: detectedElements) {
            await MainActor.run {
                selectedRegion = element.boundingBox
                highlightedElement = element
                
                // Animate the selection
                withAnimation(.easeInOut(duration: 0.3)) {
                    showShapeHint = true
                }
                
                // Hide hint after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showShapeHint = false
                    }
                }
            }
        } else {
            // Create a small region around the tap point if no element found
            let regionSize: CGFloat = 100
            let region = CGRect(
                x: point.x - regionSize/2,
                y: point.y - regionSize/2,
                width: regionSize,
                height: regionSize
            )
            
            await MainActor.run {
                selectedRegion = region
                highlightedElement = nil
            }
        }
    }
    
    private func performSearch() {
        print("=== performSearch called ===")
        
        // If no region selected but paths exist, use bounding box of all paths
        var regionToSearch = selectedRegion
        if regionToSearch == nil && !paths.isEmpty {
            print("No selected region, calculating from paths...")
            // Calculate bounding box from all paths
            var minX = CGFloat.infinity
            var minY = CGFloat.infinity
            var maxX = -CGFloat.infinity
            var maxY = -CGFloat.infinity
            
            for path in paths {
                if let bbox = path.boundingBox() {
                    minX = min(minX, bbox.minX)
                    minY = min(minY, bbox.minY)
                    maxX = max(maxX, bbox.maxX)
                    maxY = max(maxY, bbox.maxY)
                }
            }
            
            if minX != .infinity {
                regionToSearch = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                print("Calculated region from paths: \(regionToSearch!)")
            }
        }
        
        guard var region = regionToSearch,
              let image = backgroundImage else { 
            print("ERROR: No region (\(regionToSearch == nil)) or image (\(backgroundImage == nil)) selected")
            // Show error to user
            let alert = NSAlert()
            alert.messageText = "No Selection"
            alert.informativeText = "Please draw or select an area to search"
            alert.alertStyle = .warning
            alert.runModal()
            return 
        }
        
        // No conversion needed - using 1:1 display
        print("Region selected (1:1 coordinates): \(region)")
        print("Background image size: \(image.size)")
        
        isProcessing = true
        
        Task {
            do {
                print("Cropping image to converted region...")
                // Crop image to selected region (now in image coordinates)
                let croppedImage = cropImage(image, to: region)
                print("Cropped image size: \(croppedImage.size)")
                
                // Save the cropped image immediately
                await MainActor.run {
                    appState.lastCapturedImage = croppedImage
                    print("Saved cropped image to app state")
                }
                
                // Try to extract text with OCR (but don't fail if it doesn't work)
                var extractedText = ""
                do {
                    print("Attempting OCR extraction...")
                    extractedText = try await ocrManager.extractText(from: croppedImage)
                    print("OCR extracted text: \(extractedText.prefix(100))...")
                } catch {
                    print("OCR failed (non-fatal): \(error)")
                    // Continue without OCR text
                }
                
                // Search with Gemini
                let searchQuery = extractedText.isEmpty ? 
                    "What is shown in this image selection? Please describe what you see." : 
                    "Context from image: \(extractedText)\n\nPlease provide relevant information about this."
                
                print("Sending to Gemini with query: \(searchQuery.prefix(100))...")
                let result = try await geminiService.searchWithImage(
                    croppedImage,
                    text: searchQuery
                )
                print("Gemini response received: \(result.prefix(100))...")
                
                await MainActor.run {
                    print("Updating UI with results...")
                    // Update state with results
                    appState.lastExtractedText = extractedText
                    appState.searchResults = result
                    appState.isLoading = false
                    appState.showMainWindow = true
                    
                    // Clear overlay state
                    appState.showSearchOverlay = false
                    isProcessing = false
                    
                    print("Hiding overlay and showing main window...")
                    // Hide overlay window and ensure main window is visible
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.hideDrawingOverlay()
                        
                        // Ensure main window is brought to front
                        if let mainWindow = appDelegate.mainWindow {
                            print("Bringing main window to front")
                            mainWindow.makeKeyAndOrderFront(nil)
                        } else {
                            print("WARNING: Main window is nil")
                        }
                    }
                    print("=== performSearch completed successfully ===")
                }
            } catch {
                print("ERROR in performSearch: \(error)")
                print("Error details: \(error.localizedDescription)")
                
                await MainActor.run {
                    // Show error but still allow user to dismiss overlay
                    appState.errorMessage = "Search failed: \(error.localizedDescription)"
                    isProcessing = false
                    
                    // Show alert with option to retry or cancel
                    let alert = NSAlert()
                    alert.messageText = "Search Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Retry")
                    alert.addButton(withTitle: "Cancel")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        // Retry the search
                        print("User chose to retry search")
                        performSearch()
                    } else {
                        // Cancel and close overlay
                        print("User chose to cancel after error")
                        cancelDrawing()
                    }
                }
            }
        }
    }
    
    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage {
        print("cropImage called with rect: \(rect)")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("ERROR: Could not get CGImage from NSImage")
            return image
        }
        
        print("Original CGImage size: \(cgImage.width) x \(cgImage.height)")
        print("NSImage size: \(image.size)")
        
        // Calculate scale factor
        let scale = CGFloat(cgImage.width) / image.size.width
        print("Scale factor: \(scale)")
        
        // For CGImage cropping, we need to use the CGImage coordinate system
        // CGImage has origin at top-left, same as SwiftUI
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,  // Don't invert Y coordinate
            width: rect.width * scale,
            height: rect.height * scale
        )
        
        print("Scaled rect for cropping: \(scaledRect)")
        
        // Ensure the rect is within bounds
        let clampedRect = CGRect(
            x: max(0, min(scaledRect.origin.x, CGFloat(cgImage.width) - 1)),
            y: max(0, min(scaledRect.origin.y, CGFloat(cgImage.height) - 1)),
            width: min(scaledRect.width, CGFloat(cgImage.width) - scaledRect.origin.x),
            height: min(scaledRect.height, CGFloat(cgImage.height) - scaledRect.origin.y)
        )
        
        print("Clamped rect: \(clampedRect)")
        
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            print("ERROR: Invalid rect dimensions after clamping")
            return image
        }
        
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            print("ERROR: CGImage cropping failed")
            return image
        }
        
        print("Cropped CGImage size: \(croppedCGImage.width) x \(croppedCGImage.height)")
        
        // Create NSImage from cropped CGImage
        // Use the actual size of the cropped image, not the original rect size
        let actualSize = NSSize(width: CGFloat(croppedCGImage.width) / scale, 
                                height: CGFloat(croppedCGImage.height) / scale)
        let resultImage = NSImage(cgImage: croppedCGImage, size: actualSize)
        
        print("Result NSImage size: \(resultImage.size)")
        
        // Debug: Save cropped image to check if it's actually white
        if let tiffData = resultImage.tiffRepresentation {
            let debugURL = FileManager.default.temporaryDirectory.appendingPathComponent("cropped_debug.tiff")
            try? tiffData.write(to: debugURL)
            print("Debug cropped image saved to: \(debugURL.path)")
        }
        
        return resultImage
    }
    
    private func clearDrawing() {
        paths.removeAll()
        currentPath = DrawingPath()
        selectedRegion = nil
        detectedShape = .unknown
    }
    
    private func undoLastPath() {
        if !paths.isEmpty {
            paths.removeLast()
            
            // Update selected region
            if let lastPath = paths.last,
               let bbox = lastPath.boundingBox() {
                selectedRegion = bbox
            } else {
                selectedRegion = nil
            }
        }
    }
    
    private func cancelDrawing() {
        // Clear drawing state
        paths.removeAll()
        currentPath = DrawingPath()
        selectedRegion = nil
        isProcessing = false
        
        // Hide overlay window first
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.hideDrawingOverlay()
        }
        
        // Only reset overlay-related state
        appState.showSearchOverlay = false
        appState.isCapturing = false
        
        // Don't reset other state - keep main window and any previous results
    }
}

#Preview {
    DrawingOverlayView()
        .environmentObject(AppState())
}