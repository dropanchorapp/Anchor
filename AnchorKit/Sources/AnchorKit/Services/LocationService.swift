import CoreLocation
import Foundation
import Observation

/// Service for handling geolocation using CoreLocation
@Observable
public final class LocationService: NSObject, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    private var permissionCompletion: ((Bool) -> Void)?

    /// Current authorization status
    public private(set) var authorizationStatus: CLAuthorizationStatus

    /// Current location
    public private(set) var currentLocation: CLLocation?

    /// Last time location was updated
    private var lastLocationUpdate: Date?

    /// Minimum time between location updates (3 minutes)
    private let locationUpdateInterval: TimeInterval = 180

    /// Whether location services are available on the device
    public var isLocationServicesEnabled: Bool {
        // Lazy initialization on background queue to avoid blocking main thread
        if _isLocationServicesEnabled == nil {
            Task.detached {
                let enabled = CLLocationManager.locationServicesEnabled()
                await MainActor.run {
                    self._isLocationServicesEnabled = enabled
                }
            }
            // Return true optimistically during first check
            return true
        }
        return _isLocationServicesEnabled!
    }

    private var _isLocationServicesEnabled: Bool?

    /// Whether we have permission to access location
    public var hasLocationPermission: Bool {
        #if os(macOS)
        authorizationStatus == .authorized || authorizationStatus == .authorizedAlways
        #else
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #endif
    }

    /// Whether we should show a permission request (user hasn't decided yet)
    public var shouldRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    /// Whether permission was explicitly denied by the user
    public var isPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    override public init() {
        // Initialize with notDetermined, will be updated in setupLocationManager
        authorizationStatus = .notDetermined
        super.init()
        print("📍 LocationService initialized")
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Get the current authorization status from the actual location manager
        authorizationStatus = locationManager.authorizationStatus
        print("📍 Current location authorization status: \(authorizationStatus.rawValue)")

        // Don't start location updates automatically - wait for explicit requests
        // This prevents unwanted location updates that trigger view re-renders
    }

    private func startLocationUpdates() {
        guard hasLocationPermission else {
            return
        }

        // Check if we need to update location
        if let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < locationUpdateInterval {
            print("📍 Using cached location (updated \(Int(Date().timeIntervalSince(lastUpdate))) seconds ago)")
            return
        }

        print("📍 Starting fresh location updates...")
        locationManager.startUpdatingLocation()
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    /// Request location permissions and get initial location (works properly in menubar apps!)
    /// This method is optimized to avoid UI blocking by checking authorization status first
    /// and only triggering the actual permission request on a background queue when needed.
    public func requestLocationPermission() async -> Bool {
        guard isLocationServicesEnabled else {
            print("❌ Location services are disabled on this device")
            return false
        }

        // Check current status (this is safe to call from any queue)
        let currentStatus = authorizationStatus
        switch currentStatus {
        case .denied, .restricted:
            return handleDeniedPermission()

        case .authorized, .authorizedAlways:
            return await handleGrantedPermission()

        #if !os(macOS)
        case .authorizedWhenInUse:
            return await handleGrantedPermission()
        #endif

        case .notDetermined:
            return await requestPermissionFromUser()

        @unknown default:
            print("❌ Unknown location authorization status: \(authorizationStatus.rawValue)")
            return false
        }
    }

    private func handleDeniedPermission() -> Bool {
        print("❌ Location access previously denied. Please enable in System Settings:")
        print("   Privacy & Security > Location Services > anchor")
        return false
    }

    private func handleGrantedPermission() async -> Bool {
        print("✅ Location permission already granted (not requesting again)")
        // Get initial location if we don't have one yet
        await MainActor.run {
            if currentLocation == nil {
                startLocationUpdates()
            }
        }
        return true
    }

    private func requestPermissionFromUser() async -> Bool {
        print("📍 Requesting location permission...")

        // Use continuation but handle the permission request properly off main thread
        return await withCheckedContinuation { continuation in
            // Set up completion handler on main actor
            Task { @MainActor in
                self.permissionCompletion = { granted in
                    continuation.resume(returning: granted)
                }
            }

            // Dispatch authorization request to background queue to prevent UI blocking
            // This follows Apple's recommendation to avoid calling location methods on main thread
            Task.detached { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }

                // Check authorization status again right before requesting to handle race conditions
                let freshStatus = self.locationManager.authorizationStatus
                await MainActor.run {
                    self.authorizationStatus = freshStatus
                }

                // Only request if still not determined
                if freshStatus == .notDetermined {
                    // For menubar apps, this WILL trigger the system dialog
                    #if os(macOS)
                    self.locationManager.requestWhenInUseAuthorization()
                    #else
                    self.locationManager.requestWhenInUseAuthorization()
                    #endif
                } else {
                    // Status changed while we were setting up - handle it
                    let hasPermission = await MainActor.run {
                        self.hasLocationPermission
                    }
                    continuation.resume(returning: hasPermission)
                }
            }
        }
    }

    /// Get current location coordinates (passive - uses cached location, doesn't trigger updates)
    public func getCurrentCoordinates() -> (latitude: Double, longitude: Double)? {
        guard hasLocationPermission else {
            return nil
        }

        // Return cached location if available
        return currentLocation.map { location in
            (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    /// Get current location coordinates with automatic updates if needed
    public func getCurrentCoordinatesWithUpdate() -> (latitude: Double, longitude: Double)? {
        guard hasLocationPermission else {
            return nil
        }

        // If we have a current location and it's still fresh, use it
        if let location = currentLocation, !shouldUpdateLocation() {
            let age = locationAge ?? 0
            print("📍 Using cached location (age: \(Int(age))s)")
            return (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }

        // If we don't have a current location yet, or it's too old, try to get one
        if currentLocation == nil || shouldUpdateLocation() {
            print("📍 Location cache miss - requesting fresh location")
            startLocationUpdates()
        }

        return currentLocation.map { location in
            (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    /// Check if location should be updated based on time interval
    private func shouldUpdateLocation() -> Bool {
        guard let lastUpdate = lastLocationUpdate else {
            return true // Never updated
        }
        return Date().timeIntervalSince(lastUpdate) >= locationUpdateInterval
    }

    /// Get the age of the current location in seconds
    public var locationAge: TimeInterval? {
        guard let lastUpdate = lastLocationUpdate else { return nil }
        return Date().timeIntervalSince(lastUpdate)
    }

    /// Get a human-readable description of location freshness
    public var locationFreshnessDescription: String {
        guard let age = locationAge else {
            return "No location data"
        }

        if age < 60 {
            return "Just now"
        } else if age < 3600 {
            let minutes = Int(age / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = Int(age / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }

    /// Request a fresh location update (ignores cache)
    @MainActor
    public func requestCurrentLocation() async -> (latitude: Double, longitude: Double)? {
        guard hasLocationPermission else {
            return nil
        }

        // Force a fresh location update
        print("📍 Forcing fresh location update...")
        locationManager.startUpdatingLocation()

        // Give it a moment to get fresh location data
        try? await Task.sleep(for: .seconds(2))

        return getCurrentCoordinatesWithUpdate()
    }

    /// Check if location should be updated when user opens the app, and update if needed
    @MainActor
    public func checkAndUpdateLocationForAppUsage() async {
        guard hasLocationPermission else {
            return
        }

        // If we have no location yet, or if the cache has expired, get a fresh location
        if currentLocation == nil || shouldUpdateLocation() {
            print("📍 App opened - updating location (cache expired or no location)")
            startLocationUpdates()
        } else {
            let age = locationAge ?? 0
            print("📍 App opened - using cached location (age: \(Int(age))s)")
        }
    }
}

// MARK: - LocationError

public extension LocationService {
    enum LocationError: LocalizedError {
        case permissionDenied
        case locationUnavailable
        case timeout
        case unknown(Error)

        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                "Location permission denied"
            case .locationUnavailable:
                "Current location unavailable"
            case .timeout:
                "Location request timed out"
            case let .unknown(error):
                "Location error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        let newStatus = manager.authorizationStatus

        // Only update if status actually changed to prevent unnecessary SwiftUI updates
        guard oldStatus.rawValue != newStatus.rawValue else { return }

        print("📍 Location authorization changed from \(oldStatus.rawValue) to \(newStatus.rawValue)")
        authorizationStatus = newStatus

        // If we were waiting for permission, complete the request
        if let completion = permissionCompletion {
            permissionCompletion = nil

            let granted = hasLocationPermission
            print(granted ? "✅ Location permission granted!" : "❌ Location permission denied")

            // Only start location updates if permission was granted AND we're explicitly requesting it
            if granted, currentLocation == nil || shouldUpdateLocation() {
                startLocationUpdates()
            }

            completion(granted)
        }
        // Don't automatically start location updates when permission changes
        // Let the app explicitly request location when needed
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Update current location and timestamp
        currentLocation = location
        lastLocationUpdate = Date()

        let coords = location.coordinate
        print("📍 Location updated: \(String(format: "%.6f", coords.latitude)), " +
                "\(String(format: "%.6f", coords.longitude)) (cached for 3 minutes)")

        // If we were waiting for permission, complete the request
        if let completion = permissionCompletion {
            permissionCompletion = nil
            print("✅ Location permission granted! (Got location data)")
            completion(true)
        }

        // Stop updates immediately to save battery
        stopLocationUpdates()
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")

        if let completion = permissionCompletion {
            permissionCompletion = nil

            if let clError = error as? CLError, clError.code == .denied {
                print("❌ Location permission denied by user")
                completion(false)
            } else {
                // Other errors don't necessarily mean permission was denied
                print("⚠️  Location error, but permission status unclear")
                completion(hasLocationPermission)
            }
        }
    }
}
