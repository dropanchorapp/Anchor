//
//  FeedNotAuthenticatedView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct FeedNotAuthenticatedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .foregroundStyle(.orange)
                .font(.system(size: 40))

            Text("Sign in to see your feed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect your Bluesky account to see check-ins from people you follow.")
                .foregroundStyle(.secondary)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Go to Settings to sign in")
                .foregroundStyle(.blue)
                .font(.callout)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedNotAuthenticatedView()
} 
