//
//  PlaceModeSelectionView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI

struct PlaceModeSelectionView: View {
    let onModeSelected: (PlaceDiscoveryMode) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Choose how to find places:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ModeSelectionCard(
                    mode: .browse,
                    action: { onModeSelected(.browse) }
                )
                
                ModeSelectionCard(
                    mode: .search,
                    action: { onModeSelected(.search) }
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct ModeSelectionCard: View {
    let mode: PlaceDiscoveryMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(mode.icon)
                    .font(.system(size: 40))
                
                Text(mode.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlaceModeSelectionView { mode in
        print("Selected mode: \(mode)")
    }
}
