//
//  FeedPostLocationView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct FeedPostLocationView: View {
    let post: FeedPost
    var formattedAddress: String {
        guard let addressObj = post.address else { return "" }
        return LocationFormatter.shared.getLocationAddress([addressObj])
    }
    var body: some View {
        if post.coordinates != nil {
            VStack(alignment: .leading, spacing: 8) {
                // Place name - primary content
                HStack(alignment: .center, spacing: 10) {
                    Text(FeedTextProcessor.shared.extractCategoryIcon(from: post.record.text))
                        .font(.title3)
                    Text(post.address?.name ?? "Location")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                // Address - secondary location info
                if !formattedAddress.isEmpty {
                    Text(formattedAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }
} 
