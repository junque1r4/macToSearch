//
//  ElementDetector.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import Vision
import AppKit

class ElementDetector {
    
    struct DetectedElement {
        let boundingBox: CGRect
        let type: ElementType
        let confidence: Float
        let text: String?
        
        enum ElementType {
            case text
            case button
            case image
            case icon
            case unknown
        }
    }
    
    func detectElements(in image: NSImage) async throws -> [DetectedElement] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw DetectionError.invalidImage
        }
        
        var detectedElements: [DetectedElement] = []
        
        // Detect text regions
        let textElements = try await detectTextRegions(in: cgImage, imageSize: image.size)
        detectedElements.append(contentsOf: textElements)
        
        // Detect rectangles (potential buttons/containers)
        let rectangleElements = try await detectRectangles(in: cgImage, imageSize: image.size)
        detectedElements.append(contentsOf: rectangleElements)
        
        // Detect salient objects
        let salientElements = try await detectSalientObjects(in: cgImage, imageSize: image.size)
        detectedElements.append(contentsOf: salientElements)
        
        return detectedElements
    }
    
    private func detectTextRegions(in cgImage: CGImage, imageSize: NSSize) async throws -> [DetectedElement] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DetectionError.visionError(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let elements = observations.compactMap { observation -> DetectedElement? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    let boundingBox = self.convertBoundingBox(
                        observation.boundingBox,
                        imageSize: imageSize
                    )
                    
                    return DetectedElement(
                        boundingBox: boundingBox,
                        type: .text,
                        confidence: observation.confidence,
                        text: topCandidate.string
                    )
                }
                
                continuation.resume(returning: elements)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DetectionError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    private func detectRectangles(in cgImage: CGImage, imageSize: NSSize) async throws -> [DetectedElement] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DetectionError.visionError(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let elements = observations.map { observation -> DetectedElement in
                    let boundingBox = self.convertBoundingBox(
                        observation.boundingBox,
                        imageSize: imageSize
                    )
                    
                    // Heuristic: small rectangles are likely buttons
                    let area = boundingBox.width * boundingBox.height
                    let imageArea = imageSize.width * imageSize.height
                    let relativeArea = area / imageArea
                    
                    let type: DetectedElement.ElementType = relativeArea < 0.05 ? .button : .unknown
                    
                    return DetectedElement(
                        boundingBox: boundingBox,
                        type: type,
                        confidence: observation.confidence,
                        text: nil
                    )
                }
                
                continuation.resume(returning: elements)
            }
            
            request.minimumAspectRatio = 0.1
            request.maximumAspectRatio = 10.0
            request.minimumSize = 0.01
            request.maximumObservations = 20
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DetectionError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    private func detectSalientObjects(in cgImage: CGImage, imageSize: NSSize) async throws -> [DetectedElement] {
        guard #available(macOS 13.0, *) else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: DetectionError.visionError(error.localizedDescription))
                    return
                }
                
                guard let observation = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Get salient regions
                let salientObjects = observation.salientObjects ?? []
                
                let elements = salientObjects.map { object -> DetectedElement in
                    let boundingBox = self.convertBoundingBox(
                        object.boundingBox,
                        imageSize: imageSize
                    )
                    
                    return DetectedElement(
                        boundingBox: boundingBox,
                        type: .image,
                        confidence: object.confidence,
                        text: nil
                    )
                }
                
                continuation.resume(returning: elements)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: DetectionError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    private func convertBoundingBox(_ visionBox: CGRect, imageSize: NSSize) -> CGRect {
        // Convert from Vision coordinates (0-1, origin bottom-left)
        // to AppKit coordinates (pixels, origin top-left)
        let x = visionBox.origin.x * imageSize.width
        let y = (1 - visionBox.origin.y - visionBox.height) * imageSize.height
        let width = visionBox.width * imageSize.width
        let height = visionBox.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func findElementAt(point: CGPoint, in elements: [DetectedElement]) -> DetectedElement? {
        // Find the smallest element containing the point
        let containingElements = elements.filter { $0.boundingBox.contains(point) }
        return containingElements.min { $0.boundingBox.area < $1.boundingBox.area }
    }
    
    func findElementsInRegion(_ region: CGRect, in elements: [DetectedElement]) -> [DetectedElement] {
        return elements.filter { element in
            region.intersects(element.boundingBox)
        }
    }
}

extension CGRect {
    var area: CGFloat {
        return width * height
    }
}

enum DetectionError: LocalizedError {
    case invalidImage
    case visionError(String)
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .visionError(let message):
            return "Vision detection error: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}