//
//  LocationPermissionView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct LocationPermissionView: View {
    @Environment(LocationService.self) private var locationService
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Location Access Required")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Anchor needs access to your location to find nearby places where you can drop anchor.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task { @MainActor in
                    print("🔘 Button pressed - Current auth status: \(locationService.authorizationStatus.rawValue)")
                    print("📱 Device location services enabled: \(locationService.isLocationServicesEnabled)")
                    print("📱 Current location: \(locationService.currentLocation?.description ?? "nil")")
                    
                    isRequesting = true
                    
                    // Add small delay to ensure UI updates before starting permission request
                    try? await Task.sleep(for: .milliseconds(100))
                    
                    print("🔄 About to request location permission...")
                    let granted = await locationService.requestLocationPermission()
                    print("📍 Location permission result: \(granted)")
                    print("📍 New auth status: \(locationService.authorizationStatus.rawValue)")
                    print("📍 Has permission: \(locationService.hasLocationPermission)")
                    print("📍 Should request permission: \(locationService.shouldRequestPermission)")
                    print("📍 Is permission denied: \(locationService.isPermissionDenied)")
                    
                    isRequesting = false
                    
                    if granted {
                        print("✅ Location permission granted successfully")
                    } else {
                        print("❌ Location permission was denied or failed")
                    }
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isRequesting ? "Requesting..." : "Enable Location Access")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)
            
            if locationService.authorizationStatus == .denied {
                VStack(spacing: 12) {
                    Text("Location access was denied. Please enable it in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
    }
}

#Preview {
    LocationPermissionView()
        .environment(LocationService())
}
