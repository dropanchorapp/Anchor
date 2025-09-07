//
//  SearchSuggestionView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI

struct SearchSuggestionView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("Didn't find what you're looking for?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                    Text("Search for places nearby")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.accentColor)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}