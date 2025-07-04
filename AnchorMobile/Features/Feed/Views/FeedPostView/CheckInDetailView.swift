//
//  CheckInDetailView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import MapKit
import AnchorKit

struct CheckInDetailView: View {
    let post: FeedPost
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) private var dismiss
    
    init(post: FeedPost) {
        self.post = post
        // Initialize map position based on coordinates
        if let coords = post.coordinates {
            self._cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))
        } else {
            // Default to San Francisco if no location
            self._cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Interactive map that extends behind status bar and scrolls with content
                if let coords = post.coordinates {
                    Map(position: $cameraPosition) {
                        Annotation(
                            post.address?.name ?? "Location",
                            coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
                        ) {
                            VStack {
                                Text(FeedTextProcessor.shared.extractCategoryIcon(from: post.record.text))
                                    .font(.title2)
                                    .padding(8)
                                    .background(.regularMaterial, in: Circle())
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .frame(height: 300)
                    .mapStyle(.standard)
                    .mapControlVisibility(.hidden) // Hide all map controls including compass
                    .ignoresSafeArea(.all, edges: .top) // Extend behind status bar
                }
                
                // Content area
                VStack(alignment: .leading, spacing: 16) {
                    // Author info
                    HStack(spacing: 12) {
                        AsyncImage(url: post.author.avatar.flatMap(URL.init)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(.secondary)
                                .overlay {
                                    Text(String(post.author.handle.prefix(1).uppercased()))
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.author.displayName ?? post.author.handle)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("@\(post.author.handle)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(post.record.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Location details
                    if let coords = post.coordinates {
                        VStack(alignment: .leading, spacing: 12) {
                            // Place name with icon
                            HStack(spacing: 12) {
                                Text(FeedTextProcessor.shared.extractCategoryIcon(from: post.record.text))
                                    .font(.largeTitle)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.address?.name ?? "Location")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    let address: String = {
                                        if let addressObj = post.address {
                                            let locItem = LocationItem.address(.init(
                                                street: addressObj.street,
                                                locality: addressObj.locality,
                                                region: addressObj.region,
                                                country: addressObj.country,
                                                postalCode: addressObj.postalCode,
                                                name: addressObj.name
                                            ))
                                            return LocationFormatter.shared.getLocationAddress([locItem])
                                        }
                                        return ""
                                    }()
                                    if !address.isEmpty {
                                        Text(address)
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Personal message
                    if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(from: post.record.text, locations: nil) {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(personalMessage)
                                .font(.body)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if let coords = post.coordinates {
                            Button(action: {
                                ExternalAppService.shared.openInMaps(coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), locationName: post.address?.name ?? "Location")
                            }) {
                                Label("Open in Maps", systemImage: "map")
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button(action: {
                            ExternalAppService.shared.openBlueskyProfile(handle: post.author.handle)
                        }) {
                            Label("View Profile", systemImage: "person")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .overlay(alignment: .topLeading) {
            // Floating navigation buttons
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    Button("Share") {
                        // Share functionality placeholder
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Previews
#Preview("Detail View") {
    NavigationStack {
        CheckInDetailView(post: sampleCoffeeShopPost)
    }
}
 
