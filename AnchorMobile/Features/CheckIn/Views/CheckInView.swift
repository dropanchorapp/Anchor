//
//  CheckInView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct CheckInView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "location")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Drop Anchor")
                    .font(.title2)
                    .fontWeight(.medium)
                Text("Share your location with friends")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    // Check-in functionality placeholder
                }) {
                    Text("Check In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Check-in")
        }
    }
} 
