//
//  FeedPostView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostView: View {
    let post: FeedPost
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                FeedPostHeaderView(post: post)
                FeedPostLocationView(post: post)
                FeedPostMessageView(post: post)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
#Preview("Coffee Shop Check-in") {
    FeedPostView(post: sampleCoffeeShopPost) { }
        .padding()
}

#Preview("Restaurant Check-in") {
    FeedPostView(post: sampleRestaurantPost) { }
        .padding()
}

#Preview("Climbing Check-in") {
    FeedPostView(post: sampleClimbingPost) { }
        .padding()
}
