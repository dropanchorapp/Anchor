//
//  FeedPostMessageView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit
import ATProtoFoundation

struct FeedPostMessageView: View {
    let post: FeedPost

    var body: some View {
        if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
            from: post.record.text,
            locations: nil
        ) {
            Text(personalMessage)
                .font(.system(.body, design: .serif))
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeedPostMessageView(post: sampleCoffeeShopPost)
        Divider()
        FeedPostMessageView(post: sampleRestaurantPost)
        Divider()
        FeedPostMessageView(post: sampleClimbingPost)
        Spacer()
    }
    .padding()
} 
