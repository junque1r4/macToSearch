//
//  ResultsView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct ResultsView: View {
    let results: String
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Results", systemImage: "sparkles")
                    .font(.headline)
                
                Spacer()
                
                Button(action: copyResults) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(isCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help(isCopied ? "Copied!" : "Copy results")
            }
            
            ScrollView {
                Text(results)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                    )
            }
            .frame(maxHeight: 300)
        }
        .padding(.horizontal)
    }
    
    private func copyResults() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(results, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

#Preview {
    ResultsView(results: "This is a sample result from Gemini AI. It contains helpful information about your query.")
}