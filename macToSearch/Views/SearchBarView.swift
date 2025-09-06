//
//  SearchBarView.swift
//  macToSearch
//
//  Created by MacBook on 06/09/2025.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Ask anything...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: onSearch) {
                Text("Search")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchText.isEmpty)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isTextFieldFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    SearchBarView(searchText: .constant(""), onSearch: {})
}
