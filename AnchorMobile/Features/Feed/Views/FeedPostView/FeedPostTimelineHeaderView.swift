//
//  FeedPostTimelineHeaderView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 14/09/2025.
//

import SwiftUI
import AnchorKit
import ATProtoFoundation

struct FeedPostTimelineHeaderView: View {
    let post: FeedPost

    private func formatLocationContext(_ address: FeedAddress) -> String {
        // Just show locality (city) for timeline - detail view has full info
        if let locality = address.locality, !locality.isEmpty {
            return locality
        }
        return ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Place name and location context
            VStack(alignment: .leading, spacing: 4) {
                if let placeName = post.address?.name, !placeName.isEmpty {
                    Text(placeName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                } else {
                    Text("Location")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                // Show city for context
                if let addressObj = post.address {
                    let locationContext = formatLocationContext(addressObj)
                    if !locationContext.isEmpty {
                        Text(locationContext)
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Metadata: time and likes
            VStack(alignment: .trailing, spacing: 4) {
                // Relative time (e.g., "2h ago")
                Text(post.record.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Likes count (subtle display)
                if let likesCount = post.likesCount, likesCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(likesCount)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Background timeline line
        ZStack {
            HStack {
                Rectangle()
                    .fill(.orange.opacity(0.3))
                    .frame(width: 2)
                    .padding(.leading, 16 + 4)
                Spacer()
            }

            VStack(spacing: 16) {
                FeedPostTimelineHeaderView(post: sampleCoffeeShopPost)
                FeedPostTimelineHeaderView(post: sampleRestaurantPost)
                FeedPostTimelineHeaderView(post: sampleClimbingPost)
            }
            .padding(.vertical, 20)
        }
    }
    .frame(height: 300)
}
