//
//  FeedPostTimelineView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 14/09/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostTimelineView: View {
    let post: FeedPost
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                FeedPostTimelineHeaderView(post: post)

                // Image thumbnail
                if let image = post.image, let thumbURL = URL(string: image.thumbUrl) {
                    AsyncImage(url: thumbURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 200)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 200)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }

                if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
                    from: post.record.text,
                    locations: nil
                ) {
                    Text(personalMessage)
                        .font(.system(.body, design: .serif))
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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

            VStack(spacing: 0) {
                FeedPostTimelineView(post: sampleCoffeeShopPost) { }
                FeedPostTimelineView(post: sampleRestaurantPost) { }
                FeedPostTimelineView(post: sampleClimbingPost) { }
            }
        }
    }
    .frame(height: 400)
}
