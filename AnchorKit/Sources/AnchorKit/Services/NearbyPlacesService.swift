import Foundation
import CoreLocation
import Observation

/// Service that coordinates location and nearby places functionality
@Observable
public final class NearbyPlacesService: @unchecked Sendable {
    
    // MARK: - Properties
    
    public private(set) var places: [Place] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    
    private let locationService: LocationService
    private let overpassService: OverpassService
    
    // MARK: - Initialization
    
    public init(locationService: LocationService, overpassService: OverpassService = OverpassService()) {
        self.locationService = locationService
        self.overpassService = overpassService
    }
    
    // MARK: - Public Methods
    
    /// Search for nearby places using current location
    @MainActor
    public func searchNearbyPlaces() async {
        guard let coordinates = locationService.getCurrentCoordinatesWithUpdate() else {
            errorMessage = "Location not available"
            places = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            
            // Call the service - it's now Sendable so this is safe
            let foundPlaces = try await overpassService.findNearbyPlaces(near: coordinate)
            
            // Sort by distance from current location
            places = foundPlaces.sorted { place1, place2 in
                let dist1 = distanceFromCurrent(place: place1, current: coordinates)
                let dist2 = distanceFromCurrent(place: place2, current: coordinates)
                return dist1 < dist2
            }
            
        } catch {
            errorMessage = "Failed to find nearby places: \(error.localizedDescription)"
            places = []
        }
        
        isLoading = false
    }
    
    /// Refresh location and search for nearby places
    @MainActor
    public func refreshLocationAndSearch() async {
        _ = await locationService.requestCurrentLocation()
        await searchNearbyPlaces()
    }
    
    /// Clear current error message
    @MainActor
    public func clearError() {
        errorMessage = nil
    }
    
    /// Get filtered places based on search text
    public func filteredPlaces(searchText: String) -> [Place] {
        // Don't trigger location updates - only use cached location for sorting
        let coordinatesForSorting = locationService.currentLocation?.coordinate
        let sortedPlaces: [Place]
        
        if let coordinates = coordinatesForSorting {
            // Sort by distance to current location using cached coordinates
            sortedPlaces = places.sorted { place1, place2 in
                let dist1 = abs(place1.latitude - coordinates.latitude) + abs(place1.longitude - coordinates.longitude)
                let dist2 = abs(place2.latitude - coordinates.latitude) + abs(place2.longitude - coordinates.longitude)
                return dist1 < dist2
            }
        } else {
            // No location available, just return places as-is
            sortedPlaces = places
        }
        
        if searchText.isEmpty {
            return sortedPlaces
        } else {
            return sortedPlaces.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func distanceFromCurrent(place: Place, current: (latitude: Double, longitude: Double)) -> Double {
        return abs(place.latitude - current.latitude) + abs(place.longitude - current.longitude)
    }
} 