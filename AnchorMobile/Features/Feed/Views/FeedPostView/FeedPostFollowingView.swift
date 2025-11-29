//
//  FeedPostFollowingView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 14/09/2025.
//

import SwiftUI
import AnchorKit
import ATProtoFoundation

struct FeedPostFollowingView: View {
    let post: FeedPost
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                FeedPostHeaderView(post: post, showFullDate: true)
                
                VStack(alignment: .leading) {
                    FeedPostLocationView(post: post)
                    Text(post.record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
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
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    List {
        FeedPostFollowingView(post: sampleCoffeeShopPost) { }
        FeedPostFollowingView(post: sampleRestaurantPost) { }
        FeedPostFollowingView(post: sampleClimbingPost) { }
    }
    .listStyle(.plain)
}
