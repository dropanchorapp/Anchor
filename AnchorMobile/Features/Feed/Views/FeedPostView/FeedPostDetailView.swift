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
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title2)
                                    .foregroundStyle(.primary)
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
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            Text("@\(post.author.handle)")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(post.record.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Image attachment
                    if let image = post.image, let fullsizeURL = URL(string: image.fullsizeUrl) {
                        VStack(alignment: .leading, spacing: 8) {
                            AsyncImage(url: fullsizeURL) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(height: 300)
                                        .overlay {
                                            ProgressView()
                                        }
                                case .success(let displayImage):
                                    displayImage
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                case .failure:
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(height: 300)
                                        .overlay {
                                            VStack {
                                                Image(systemName: "photo")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(.secondary)
                                                Text("Failed to load image")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }

                            if let alt = image.alt, !alt.isEmpty {
                                Text(alt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        }
                    }

                    // Location details
                    if post.coordinates != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            // Place name
                            VStack(alignment: .leading, spacing: 6) {
                                Text(post.address?.name ?? "Location")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                let address: String = {
                                    if let addressObj = post.address {
                                        // Use ATProtoAddress if available, or create a struct conforming to LocationRepresentable
                                        return LocationFormatter.shared.getLocationAddress([addressObj])
                                    }
                                    return ""
                                }()
                                if !address.isEmpty {
                                    Text(address)
                                        .font(.callout)
                                        .fontWeight(.regular)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Personal message
                    if let personalMessage = FeedTextProcessor.shared.extractPersonalMessage(
                        from: post.record.text,
                        locations: nil
                    ) {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Text(personalMessage)
                                .font(.system(.body, design: .serif))
                                .fontWeight(.regular)
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if let coords = post.coordinates {
                            Button(action: {
                                ExternalAppService.shared.openInMaps(
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: coords.latitude,
                                        longitude: coords.longitude
                                    ),
                                    locationName: post.address?.name ?? "Location"
                                )
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

                    // Delete button (only show if user is the author)
                    if authStore.credentials?.did == post.author.did {
                        Divider()
                            .padding(.vertical, 8)

                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
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
                        item: "Dropped anchor at \(post.address?.name ?? "a location") https://dropanchor.app/checkin/\(post.id)",
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
        guard let sessionId = authStore.credentials?.sessionId else {
            deleteError = "Not authenticated"
            return
        }

        isDeleting = true
        deleteError = nil

        do {
            try await feedStore.deleteCheckin(post, sessionId: sessionId)
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
 
