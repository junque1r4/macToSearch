//
//  ImagePreviewBar.swift
//  macToSearch
//
//  Created by Assistant on 07/09/2025.
//

import SwiftUI
import AppKit

struct ImagePreviewBar: View {
    @Binding var images: [NSImage]
    
    var body: some View {
        Group {
            if images.count > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    // Image count
                    HStack {
                        Text("\(images.count) imagens anexadas")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Clear all button
                        if images.count > 1 {
                            Button("Limpar tudo") {
                                images.removeAll()
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Thumbnails
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<images.count, id: \.self) { index in
                                if index < images.count {
                                    ImageThumbnailView(
                                        image: images[index],
                                        onDelete: {
                                            if index < images.count {
                                                images.remove(at: index)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 80)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct ImageThumbnailView: View {
    let image: NSImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}