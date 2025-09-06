//
//  DrawingPath.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import Foundation
import SwiftUI

struct DrawingPath: Identifiable {
    let id = UUID()
    var path: Path
    var points: [CGPoint]
    var strokeColor: Color
    var lineWidth: CGFloat
    var isComplete: Bool
    
    init(strokeColor: Color = .red, lineWidth: CGFloat = 3) {
        self.path = Path()
        self.points = []
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.isComplete = false
    }
    
    mutating func addPoint(_ point: CGPoint) {
        if points.isEmpty {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
        points.append(point)
    }
    
    mutating func complete() {
        isComplete = true
    }
    
    func boundingBox() -> CGRect? {
        guard !points.isEmpty else { return nil }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    func isClosedShape(threshold: CGFloat = 30) -> Bool {
        guard points.count > 3 else { return false }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        let distance = sqrt(pow(lastPoint.x - firstPoint.x, 2) + pow(lastPoint.y - firstPoint.y, 2))
        return distance < threshold
    }
    
    func detectShape() -> DetectedShape {
        guard points.count > 2 else { return .unknown }
        
        if isClosedShape() {
            if isRectangular() {
                return .rectangle
            } else if isCircular() {
                return .circle
            } else {
                return .freeform
            }
        }
        
        return .line
    }
    
    private func isRectangular() -> Bool {
        guard points.count > 10 else { return false }
        
        // Simple heuristic: check if most angles are close to 90 degrees
        var rightAngleCount = 0
        let angleThreshold: CGFloat = 20 // degrees
        
        for i in 1..<points.count-1 {
            let angle = angleBetweenPoints(points[i-1], points[i], points[i+1])
            if abs(angle - 90) < angleThreshold || abs(angle - 270) < angleThreshold {
                rightAngleCount += 1
            }
        }
        
        return rightAngleCount >= 2
    }
    
    private func isCircular() -> Bool {
        guard let box = boundingBox() else { return false }
        
        // Check aspect ratio (should be close to 1 for circle)
        let aspectRatio = box.width / box.height
        guard aspectRatio > 0.7 && aspectRatio < 1.3 else { return false }
        
        // Check if points are distributed around a center
        let center = CGPoint(x: box.midX, y: box.midY)
        let averageRadius = box.width / 2
        
        var deviations: [CGFloat] = []
        for point in points {
            let distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
            deviations.append(abs(distance - averageRadius))
        }
        
        let averageDeviation = deviations.reduce(0, +) / CGFloat(deviations.count)
        return averageDeviation < averageRadius * 0.3
    }
    
    private func angleBetweenPoints(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let v2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let angle1 = atan2(v1.y, v1.x)
        let angle2 = atan2(v2.y, v2.x)
        
        var angle = (angle2 - angle1) * 180 / .pi
        if angle < 0 { angle += 360 }
        
        return angle
    }
}

enum DetectedShape {
    case rectangle
    case circle
    case freeform
    case line
    case unknown
    
    var description: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .freeform: return "Freeform"
        case .line: return "Line"
        case .unknown: return "Unknown"
        }
    }
}