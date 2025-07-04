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
                // Header: Author info and timestamp
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
                    
                    // Timestamp
                    Text(post.record.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)

                // Main content: Location/Place
                if let coords = post.coordinates {
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
                        if let addressObj = post.address {
                            let locItem = LocationItem.address(.init(
                                street: addressObj.street,
                                locality: addressObj.locality,
                                region: addressObj.region,
                                country: addressObj.country,
                                postalCode: addressObj.postalCode,
                                name: addressObj.name
                            ))
                            let address = LocationFormatter.shared.getLocationAddress([locItem])
                            if !address.isEmpty {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                }
                
                // User's personal message (if different from just location)
                if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(from: post.record.text, locations: nil) {
                    Text(personalMessage)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                }
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
