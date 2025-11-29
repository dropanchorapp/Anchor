//
//  FeedPostDetailComponents.swift
//  AnchorMobile
//
//  View components for FeedPostDetailView
//

import SwiftUI
import MapKit
import AnchorKit
import ATProtoFoundation

// MARK: - Author Component

struct FeedPostAuthorView: View {
    let author: FeedAuthor

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: author.avatar.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.secondary)
                    .overlay {
                        Text(String(author.handle.prefix(1).uppercased()))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(author.displayName ?? author.handle)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("@\(author.handle)")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Image Component

struct FeedPostImageView: View {
    let image: FeedImage

    var body: some View {
        if let fullsizeURL = URL(string: image.fullsizeUrl) {
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
                        .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Map Component

struct FeedPostMapView: View {
    let coordinates: FeedCoordinates
    let address: FeedAddress?
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation(
                address?.name ?? "Location",
                coordinate: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
            ) {
                Button {
                    ExternalAppService.shared.openInMaps(
                        coordinate: CLLocationCoordinate2D(
                            latitude: coordinates.latitude,
                            longitude: coordinates.longitude
                        ),
                        locationName: address?.name ?? "Location"
                    )
                } label: {
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
        .mapControlVisibility(.hidden)
        .ignoresSafeArea(.all, edges: .top)
    }
}
