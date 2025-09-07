//
//  FloatingCardView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct FloatingCardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 10
    var hoverScale: CGFloat = 1.03
    
    @State private var isHovered = false
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 10,
        hoverScale: CGFloat = 1.03,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.hoverScale = hoverScale
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.1),
                                        Color.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.15 : 0.08),
                radius: isHovered ? shadowRadius * 1.5 : shadowRadius,
                x: 0,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isHovered ? hoverScale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// Glassmorphism card variant
struct GlassCardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    
    @State private var isHovered = false
    
    init(
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Blur effect
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                }
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// Visual effect blur for glassmorphism
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Action card for quick actions
struct ActionCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            FloatingCardView(padding: 0, cornerRadius: 20) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.2), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(20)
                .frame(width: 140, height: 140)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Floating Card")
                    .font(.headline)
                Text("This is a beautiful floating card with material design")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        HStack(spacing: 16) {
            ActionCardView(
                icon: "camera.fill",
                title: "Capture",
                subtitle: "Screenshot",
                color: .blue,
                action: {}
            )
            
            ActionCardView(
                icon: "doc.on.clipboard",
                title: "Clipboard",
                subtitle: "From clipboard",
                color: .green,
                action: {}
            )
            
            ActionCardView(
                icon: "magnifyingglass",
                title: "Search",
                subtitle: "Type to search",
                color: .purple,
                action: {}
            )
        }
    }
    .padding(40)
    .frame(width: 600, height: 400)
    .background(Color(NSColor.windowBackgroundColor))
}