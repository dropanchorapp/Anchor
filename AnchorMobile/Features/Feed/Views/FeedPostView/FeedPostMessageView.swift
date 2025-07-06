//
//  FeedPostMessageView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostMessageView: View {
    let post: FeedPost
    var body: some View {
        if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
            from: post.record.text,
            locations: nil
        ) {
            Text(personalMessage)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
        }
    }
} 
