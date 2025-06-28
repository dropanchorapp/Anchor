//
//  FeedErrorView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct FeedErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
                .font(.system(size: 40))

            Text("Feed Unavailable")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .foregroundStyle(.secondary)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedErrorView(error: URLError(.notConnectedToInternet)) {
        print("Retry tapped")
    }
} 
