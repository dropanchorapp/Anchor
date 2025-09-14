//
//  FeedPostTimelineHeaderView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 14/09/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostTimelineHeaderView: View {
    let post: FeedPost

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Circle()
                .fill(.orange)
                .frame(width: 8, height: 8)
                .alignmentGuide(.firstTextBaseline) { _ in 10 }

            VStack(alignment: .leading, spacing: 4) {
                // Place name aligned to top
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

                // Address if different from place name
                if let addressObj = post.address {
                    let address = LocationFormatter.shared.getLocationAddress([addressObj])
                    let placeName = post.address?.name ?? ""
                    if !address.isEmpty && address != placeName {
                        Text(address)
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 8) // Space between timeline and text

            Spacer()

            // Time aligned to top
            Text(post.record.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .fontWeight(.regular)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
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
