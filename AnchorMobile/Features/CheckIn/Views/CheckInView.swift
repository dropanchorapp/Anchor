//
//  CheckInView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct CheckInView: View {
    @Environment(LocationService.self) private var locationService
    @State private var selectedPlace: Place?
    @State private var showingNearbyPlaces = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch locationService.authorizationStatus {
                case .notDetermined, .denied, .restricted:
                    LocationPermissionView()
                case .authorizedWhenInUse, .authorizedAlways:
                    if locationService.currentLocation != nil {
                        CheckInMainView(onFindPlaces: {
                            showingNearbyPlaces = true
                        })
                    } else {
                        LoadingLocationView()
                            .onAppear {
                                print("📍 CheckInView: Permission granted but no location yet")
                                print("📍 Location age: \(locationService.locationFreshnessDescription)")
                                Task {
                                    await locationService.checkAndUpdateLocationForAppUsage()
                                }
                            }
                    }
                @unknown default:
                    LocationPermissionView()
                }
            }
            .navigationTitle("Drop Anchor")
            .sheet(isPresented: $showingNearbyPlaces) {
                NearbyPlacesView { place in
                    selectedPlace = place
                    showingNearbyPlaces = false
                }
            }
            .sheet(item: $selectedPlace) { place in
                CheckInComposeView(place: place)
            }
        }
    }
}

struct CheckInMainView: View {
    let onFindPlaces: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Text("Find nearby places where you can check in and share your location with friends.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Actions
            VStack(spacing: 16) {
                Button(action: onFindPlaces) {
                    Label("Find Nearby Places", systemImage: "location.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct LoadingLocationView: View {
    @Environment(LocationService.self) private var locationService
    @State private var timeoutReached = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Getting your location...")
                .font(.headline)
                .fontWeight(.medium)
            
            Text(timeoutReached 
                ? "Location request is taking longer than expected" 
                : "Please wait while we find your current location")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if timeoutReached {
                Button("Request Location Again") {
                    timeoutReached = false
                    Task {
                        _ = await locationService.requestCurrentLocation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(10))
                timeoutReached = true
            }
        }
    }
}

#Preview {
    CheckInView()
        .environment(LocationService())
}
