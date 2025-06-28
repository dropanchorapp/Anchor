import Foundation

// MARK: - AnchorPDS Service Protocol

@MainActor
public protocol AnchorPDSServiceProtocol {
    func createCheckin(place: Place, customMessage: String?, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse
    func listUserCheckins(limit: Int, cursor: String?, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse
    func getGlobalFeed(limit: Int, cursor: String?, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse
}

// MARK: - AnchorPDS Service Implementation

@MainActor
public final class AnchorPDSService: AnchorPDSServiceProtocol {
    // MARK: - Properties

    private let client: AnchorPDSClientProtocol

    // MARK: - Initialization

    public convenience init(session: URLSessionProtocol = URLSession.shared) {
        let client = AnchorPDSClient(session: session)
        self.init(client: client)
    }

    public init(client: AnchorPDSClientProtocol) {
        self.client = client
    }

    // MARK: - Check-in Creation

    public func createCheckin(place: Place, customMessage: String?, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse {
        // Create check-in text
        let checkinText = buildCheckinText(for: place, customMessage: customMessage)

        // Build location items using community lexicon types
        var locations: [LocationItem] = []

        // Add geo location
        let geoLocation = CommunityGeoLocation(latitude: place.latitude, longitude: place.longitude)
        locations.append(.geo(geoLocation))

        // Add address location if we have address data
        let addressLocation = buildAddressLocation(from: place)
        if let addressLocation {
            locations.append(.address(addressLocation))
        }

        // Create the lexicon-compliant check-in record
        let checkinRecord = AnchorPDSCheckinRecord(
            text: checkinText,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            locations: locations.isEmpty ? nil : locations,
            category: place.category,
            categoryGroup: place.categoryGroup?.rawValue,
            categoryIcon: place.icon
        )

        // Create the request
        let request = AnchorPDSCreateRecordRequest(record: checkinRecord)

        do {
            let response = try await client.createRecord(request: request, credentials: credentials)
            print("✅ Successfully created check-in on AnchorPDS: \(response.uri)")
            return response
        } catch {
            print("❌ Failed to create check-in on AnchorPDS: \(error)")
            throw error
        }
    }

    // MARK: - Feed Operations

    public func listUserCheckins(limit: Int = AnchorConfig.shared.maxNearbyPlaces, cursor: String? = nil, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse {
        do {
            let response = try await client.listCheckins(
                user: nil, // nil means current user's check-ins
                limit: limit,
                cursor: cursor,
                credentials: credentials
            )
            print("✅ Retrieved \(response.checkins.count) user check-ins from AnchorPDS")
            return response
        } catch {
            print("❌ Failed to retrieve user check-ins from AnchorPDS: \(error)")
            throw error
        }
    }

    public func getGlobalFeed(limit: Int = AnchorConfig.shared.maxNearbyPlaces, cursor: String? = nil, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse {
        do {
            let response = try await client.getGlobalFeed(
                limit: limit,
                cursor: cursor,
                credentials: credentials
            )
            print("✅ Retrieved \(response.checkins.count) check-ins from AnchorPDS global feed")
            return response
        } catch {
            print("❌ Failed to retrieve global feed from AnchorPDS: \(error)")
            throw error
        }
    }

    // MARK: - Private Helper Methods

    private func buildAddressLocation(from place: Place) -> CommunityAddressLocation? {
        let tags = place.tags

        // Build street address
        var streetComponents: [String] = []
        if let housenumber = tags["addr:housenumber"] {
            streetComponents.append(housenumber)
        }
        if let street = tags["addr:street"] {
            streetComponents.append(street)
        }
        let street = streetComponents.isEmpty ? nil : streetComponents.joined(separator: " ")

        let locality = tags["addr:city"] ?? tags["addr:locality"]
        let region = tags["addr:state"] ?? tags["addr:region"]
        let country = tags["addr:country"]
        let postalCode = tags["addr:postcode"] ?? tags["addr:postal_code"]

        // Only create address if we have at least one component
        if street != nil || locality != nil || region != nil || country != nil || postalCode != nil {
            return CommunityAddressLocation(
                street: street,
                locality: locality,
                region: region,
                country: country,
                postalCode: postalCode,
                name: place.name
            )
        }

        return nil
    }

    /// Builds the text content for check-in records stored on AnchorPDS
    ///
    /// **IMPORTANT DESIGN DECISION:**
    /// Check-in records contain ONLY the user's original message, without any additional
    /// formatting, location info, or hashtags. This keeps the record clean and preserves
    /// exactly what the user intended to say.
    ///
    /// Location information is stored separately in structured `locations` fields,
    /// not mixed into the text content.
    ///
    /// This is different from Bluesky posts, which include marketing taglines and hashtags
    /// for social media engagement (see `RichTextProcessor.buildCheckinText()`).
    ///
    /// - Parameters:
    ///   - place: The place being checked into (used for structured location data)
    ///   - customMessage: The user's original message, if any
    /// - Returns: The user's exact message, or empty string if no message provided
    private func buildCheckinText(for place: Place, customMessage: String?) -> String {
        // Store only the user's original message - no additional formatting
        if let customMessage, !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customMessage
        }

        // If no custom message, store empty string
        // Location context is preserved in structured location fields
        return ""
    }
}
