//
//  PlaceTabBarView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI

struct PlaceTabBarView: View {
    let selectedMode: PlaceDiscoveryMode
    let onModeChanged: (PlaceDiscoveryMode) -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            TabButton(
                mode: .browse,
                isSelected: selectedMode == .browse,
                action: { onModeChanged(.browse) }
            )
            
            TabButton(
                mode: .search,
                isSelected: selectedMode == .search,
                action: { onModeChanged(.search) }
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct TabButton: View {
    let mode: PlaceDiscoveryMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(mode.icon)
                    .font(.title3)
                Text(mode.title)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        PlaceTabBarView(
            selectedMode: .browse,
            onModeChanged: { mode in
                print("Mode changed to: \(mode)")
            }
        )
        
        PlaceTabBarView(
            selectedMode: .search,
            onModeChanged: { mode in
                print("Mode changed to: \(mode)")
            }
        )
    }
}
