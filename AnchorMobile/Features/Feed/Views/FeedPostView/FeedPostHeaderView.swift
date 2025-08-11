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
    var body: some View {
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
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.displayName ?? post.author.handle)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("@\(post.author.handle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            // Timestamp - show time only since date is in section header
            Text(post.record.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }
} 
