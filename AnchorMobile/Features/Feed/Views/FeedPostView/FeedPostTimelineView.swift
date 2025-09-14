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
                
                if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
                    from: post.record.text,
                    locations: nil
                ) {
                    Text(personalMessage)
                        .font(.system(.body, design: .serif))
                        .fontWeight(.regular)
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .padding(.leading, 40)
                        .padding(.trailing, 16)
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
