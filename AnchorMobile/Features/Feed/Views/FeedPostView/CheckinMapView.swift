//
//  CheckinMapView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import MapKit
import CoreLocation

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

/// Map view for displaying check-in locations (deprecated in favor of CheckInDetailView)
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
