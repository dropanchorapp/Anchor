//
//  FeedPostView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit
import MapKit
import CoreLocation

struct FeedPostView: View {
    let post: FeedPost
    @State private var showingMap = false
    @State private var selectedLocation: LocationInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info (tappable for profile)
            Button(action: {
                openBlueskyProfile(handle: post.author.handle)
            }) {
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
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("@\(post.author.handle)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(post.record.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Check-in content
            VStack(alignment: .leading, spacing: 8) {
                Text(.init(post.record.formattedText))
                    .font(.body)
                
                // Show location info if available from checkin record (tappable for map)
                if let checkinRecord = post.checkinRecord,
                   let locations = checkinRecord.locations,
                   !locations.isEmpty {
                    Button(action: {
                        if let locationInfo = prepareLocationForMap(locations) {
                            selectedLocation = locationInfo
                            showingMap = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(checkinRecord.categoryIcon ?? extractCategoryIcon(from: post.record.text))
                                .foregroundStyle(.blue)
                                .font(.callout)
                            
                            Text(formatLocationInfo(locations))
                                .font(.callout)
                                .foregroundStyle(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .sheet(isPresented: $showingMap) {
            if let selectedLocation = selectedLocation {
                CheckinMapView(locationInfo: selectedLocation)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openBlueskyProfile(handle: String) {
        let cleanHandle = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        
        // Try to open in Bluesky app first
        if let blueskyAppURL = URL(string: "bluesky://profile/\(cleanHandle)"),
           UIApplication.shared.canOpenURL(blueskyAppURL) {
            UIApplication.shared.open(blueskyAppURL)
        } else {
            // Fallback to web browser
            if let webURL = URL(string: "https://bsky.app/profile/\(cleanHandle)") {
                UIApplication.shared.open(webURL)
            }
        }
    }
    
    private func prepareLocationForMap(_ locations: [LocationItem]) -> LocationInfo? {
        // Extract coordinates and address information
        var coordinate: CLLocationCoordinate2D?
        var address: String?
        var placeName: String?
        
        for location in locations {
            switch location {
            case .geo(let geoData):
                if let lat = Double(geoData.latitude), let lon = Double(geoData.longitude) {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                
            case .address(let addressData):
                placeName = addressData.name
                address = formatAddressData(addressData)
            }
        }
        
        // Must have coordinates to show on map
        guard let coordinate = coordinate else { return nil }
        
        return LocationInfo(
            coordinate: coordinate,
            placeName: placeName,
            address: address
        )
    }
    
    private func formatAddressData(_ addressData: CommunityAddressLocation) -> String {
        var components: [String] = []
        
        if let street = addressData.street {
            components.append(street)
        }
        
        if let locality = addressData.locality {
            components.append(locality)
        }
        
        if let region = addressData.region {
            components.append(region)
        }
        
        if let country = addressData.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func formatLocationInfo(_ locations: [LocationItem]) -> String {
        // Format multiple locations nicely
        let locationNames = locations.compactMap { location in
            switch location {
            case .geo(let geoData):
                // Geo location only has coordinates, not a name
                return "📍 \(geoData.latitude), \(geoData.longitude)"
            case .address(let addressData):
                // Use the name if available, otherwise build from address components
                if let name = addressData.name {
                    return name
                } else {
                    // Build address string from available components
                    let components = [
                        addressData.street,
                        addressData.locality,
                        addressData.region,
                        addressData.country
                    ].compactMap { $0 }
                    return components.isEmpty ? "Address" : components.joined(separator: ", ")
                }
            }
        }
        
        if locationNames.isEmpty {
            return "Location shared"
        } else if locationNames.count == 1 {
            return locationNames[0]
        } else {
            return locationNames.joined(separator: " • ")
        }
    }
    
    private func extractCategoryIcon(from text: String) -> String {
        // Extract emoji from check-in text as fallback
        let emojis = text.unicodeScalars.filter { $0.properties.isEmoji }
        return emojis.isEmpty ? "📍" : String(emojis.first!)
    }
}

// MARK: - Supporting Types

/// Location information for map display
struct LocationInfo: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let placeName: String?
    let address: String?
    
    init(coordinate: CLLocationCoordinate2D, placeName: String?, address: String?) {
        self.coordinate = coordinate
        self.placeName = placeName
        self.address = address
    }
}

/// Map view for displaying check-in locations
struct CheckinMapView: View {
    let locationInfo: LocationInfo
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) private var dismiss
    
    init(locationInfo: LocationInfo) {
        self.locationInfo = locationInfo
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: locationInfo.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map with pin
                Map(position: $cameraPosition) {
                    Annotation(
                        locationInfo.placeName ?? "Check-in Location",
                        coordinate: locationInfo.coordinate
                    ) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title)
                                .background(.white, in: Circle())
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Location info overlay
                VStack {
                    Spacer()
                    
                    if locationInfo.placeName != nil || locationInfo.address != nil {
                        locationInfoCard
                            .padding()
                    }
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openInMaps) {
                        Image(systemName: "map")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var locationInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let placeName = locationInfo.placeName {
                Text(placeName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if let address = locationInfo.address {
                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Coordinates
            Text("📍 \(formatCoordinate(locationInfo.coordinate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    
    private func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        let latDirection = coordinate.latitude >= 0 ? "N" : "S"
        let lonDirection = coordinate.longitude >= 0 ? "E" : "W"
        
        return String(format: "%.4f°%@ %.4f°%@", 
                     abs(coordinate.latitude), latDirection,
                     abs(coordinate.longitude), lonDirection)
    }
    
    private func openInMaps() {
        let location = CLLocation(latitude: locationInfo.coordinate.latitude, 
                                 longitude: locationInfo.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = locationInfo.placeName ?? "Check-in Location"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue
        ])
    }
} 