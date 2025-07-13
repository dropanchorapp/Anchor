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
            Image("anchor-no-locations")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )

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
