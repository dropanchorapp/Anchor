//
//  FeedEmptyView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct FeedEmptyView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.bubble")
                .foregroundStyle(.secondary)
                .font(.system(size: 40))

            Text("No check-ins found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No check-ins found in the global feed.")
                .foregroundStyle(.secondary)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedEmptyView {
        print("Refresh tapped")
    }
} 
