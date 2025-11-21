//
//  FeedPostDetailView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import MapKit
import AnchorKit

struct FeedPostDetailView: View {
    let post: FeedPost
    @State private var cameraPosition: MapCameraPosition
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var authStore
    @Environment(FeedStore.self) private var feedStore

    private func formatLocationDetails(_ address: FeedAddress) -> String {
        var parts: [String] = []

        if let locality = address.locality, !locality.isEmpty {
            parts.append(locality)
        }
        if let region = address.region, !region.isEmpty {
            parts.append(region)
        }
        if let country = address.country, !country.isEmpty {
            parts.append(country)
        }

        return parts.joined(separator: ", ")
    }

    private var shareText: String {
        // Build URL with DID for permanent link
        let url = "https://dropanchor.app/checkin/\(post.author.did)/\(post.id)"

        // Use personal message if available, otherwise use "Dropped anchor" fallback
        if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
            from: post.record.text,
            locations: nil
        ) {
            return "\(personalMessage) \(url)"
        } else {
            return "Dropped anchor at \(post.address?.name ?? "a location") \(url)"
        }
    }

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
                // Interactive map
                if let coords = post.coordinates {
                    FeedPostMapView(
                        coordinates: coords,
                        address: post.address,
                        cameraPosition: $cameraPosition
                    )
                }

                // Content area
                VStack(alignment: .leading, spacing: 16) {
                    // Author info
                    FeedPostAuthorView(author: post.author)

                    // Image attachment
                    if let image = post.image {
                        FeedPostImageView(image: image)
                    }

                    // Location details
                    if post.coordinates != nil {
                        HStack(alignment: .top, spacing: 12) {
                            // Place name and location
                            VStack(alignment: .leading, spacing: 6) {
                                Text(post.address?.name ?? "Location")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                // Show locality, region, country
                                if let addressObj = post.address {
                                    let locationDetails = formatLocationDetails(addressObj)
                                    if !locationDetails.isEmpty {
                                        Text(locationDetails)
                                            .font(.callout)
                                            .fontWeight(.regular)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                // Likes count (prominent display)
                                if let likesCount = post.likesCount, likesCount > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                            .font(.callout)
                                        Text("\(likesCount)")
                                            .font(.callout)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                }
                            }

                            Spacer()

                            // Date and time
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(post.record.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Text(post.record.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Personal message
                    if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
                        from: post.record.text,
                        locations: nil
                    ) {
                        Divider()

                        Text(personalMessage)
                            .font(.system(.body, design: .serif))
                            .fontWeight(.regular)
                            .foregroundStyle(.primary)
                            .lineSpacing(2)
                    }

                    // Action buttons
                    Divider()
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        if let coords = post.coordinates {
                            Button {
                                ExternalAppService.shared.openInMaps(
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: coords.latitude,
                                        longitude: coords.longitude
                                    ),
                                    locationName: post.address?.name ?? "Location"
                                )
                            } label: {
                                Label("Open in Maps", systemImage: "map")
                            }
                            .font(.callout)
                            .fontWeight(.medium)
                        }

                        Button {
                            ExternalAppService.shared.openBlueskyProfile(handle: post.author.handle)
                        } label: {
                            Label("View Profile", systemImage: "person")
                        }
                        .font(.callout)
                        .fontWeight(.medium)

                        // Delete button (only show if user is the author)
                        if authStore.credentials?.did == post.author.did {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                if isDeleting {
                                    HStack {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Deleting...")
                                    }
                                } else {
                                    Label("Delete Check-in", systemImage: "trash")
                                }
                            }
                            .font(.callout)
                            .fontWeight(.medium)
                            .disabled(isDeleting)

                            if let error = deleteError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.top, 4)
                            }
                        }
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

                    ShareLink(
                        item: shareText,
                        subject: Text("Check-in at \(post.address?.name ?? "a location")")
                    ) {
                        Text("Share")
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
        .confirmationDialog(
            "Delete this check-in?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await handleDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Delete Handler

    private func handleDelete() async {
        guard authStore.credentials?.sessionId != nil else {
            deleteError = "Not authenticated"
            return
        }

        isDeleting = true
        deleteError = nil

        do {
            try await feedStore.deleteCheckin(post)
            dismiss()
        } catch {
            isDeleting = false
            deleteError = "Failed to delete: \(error.localizedDescription)"
        }
    }
}

// MARK: - Previews
#Preview("Detail View") {
    NavigationStack {
        FeedPostDetailView(post: sampleCoffeeShopPost)
    }
}
