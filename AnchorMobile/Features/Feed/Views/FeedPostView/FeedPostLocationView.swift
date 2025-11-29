//
//  FeedPostLocationView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit
import ATProtoFoundation

struct FeedPostLocationView: View {
    let post: FeedPost
    
    var locationDisplayName: String {
        // Use address name if available
        if let addressName = post.address?.name, !addressName.isEmpty {
            return addressName
        }
        
        // Use LocationFormatter to build name from address components
        if let addressObj = post.address {
            let name = LocationFormatter.shared.getLocationName([addressObj])
            if name != "Unknown Location" {
                return name
            }
        }
        
        // Backend should now always provide venue names, but fallback gracefully
        return "Checked in"
    }
    
    var formattedAddress: String {
        guard let addressObj = post.address else { return "" }
        
        let address = LocationFormatter.shared.getLocationAddress([addressObj])
        
        // Don't show address if it's the same as the location name
        if address == locationDisplayName {
            return ""
        }
        
        return address
    }
    
    var body: some View {
        if post.coordinates != nil {
            VStack(alignment: .leading) {
                // Place name - primary content
                Text(locationDisplayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Address - secondary location info
                if !formattedAddress.isEmpty {
                    Text(formattedAddress)
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeedPostLocationView(post: sampleCoffeeShopPost)
        Divider()
        FeedPostLocationView(post: sampleRestaurantPost)
        Divider()
        FeedPostLocationView(post: sampleClimbingPost)
        Spacer()
    }
    .padding()
} 
