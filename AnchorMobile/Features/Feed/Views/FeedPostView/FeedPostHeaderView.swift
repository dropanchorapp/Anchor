//
//  FeedPostHeaderView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostHeaderView: View {
    let post: FeedPost
    let showFullDate: Bool

    init(post: FeedPost, showFullDate: Bool = false) {
        self.post = post
        self.showFullDate = showFullDate
    }

    var body: some View {
        if showFullDate {
            // Following feed: vertical layout with full date below author info
            VStack(alignment: .leading, spacing: 6) {
                // Author info
                HStack(spacing: 10) {
                    AsyncImage(url: post.author.avatar.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(.secondary)
                            .overlay {
                                Text(String(post.author.handle.prefix(1).uppercased()))
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                            }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author.displayName ?? post.author.handle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("@\(post.author.handle)")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        } else {
            // Timeline feed: horizontal layout with time on the right
            HStack(spacing: 12) {
                // Author info
                HStack(spacing: 10) {
                    AsyncImage(url: post.author.avatar.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(.secondary)
                            .overlay {
                                Text(String(post.author.handle.prefix(1).uppercased()))
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                            }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author.displayName ?? post.author.handle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("@\(post.author.handle)")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Time only, positioned on the right
                Text(post.record.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Following Feed Header") {
    VStack(spacing: 16) {
        FeedPostHeaderView(post: sampleCoffeeShopPost, showFullDate: true)
        FeedPostHeaderView(post: sampleRestaurantPost, showFullDate: true)
        FeedPostHeaderView(post: sampleClimbingPost, showFullDate: true)
    }
    .padding()
}

#Preview("Timeline Feed Header") {
    VStack(spacing: 16) {
        FeedPostHeaderView(post: sampleCoffeeShopPost, showFullDate: false)
        FeedPostHeaderView(post: sampleRestaurantPost, showFullDate: false)
        FeedPostHeaderView(post: sampleClimbingPost, showFullDate: false)
    }
    .padding()
} 
