import Foundation

// MARK: - Bluesky Check-in Service Protocol

@MainActor
public protocol BlueskyCheckinServiceProtocol {
    func createCheckin(place: Place, customMessage: String?, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse
    func createCheckinWithPost(place: Place, customMessage: String?, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse
}

// MARK: - Bluesky Check-in Service

@MainActor
public final class BlueskyCheckinService: BlueskyCheckinServiceProtocol {
    // MARK: - Properties

    private let client: ATProtoClientProtocol
    private let richTextProcessor: RichTextProcessorProtocol
    private let postService: BlueskyPostServiceProtocol

    // MARK: - Initialization

    public init(
        client: ATProtoClientProtocol,
        richTextProcessor: RichTextProcessorProtocol,
        postService: BlueskyPostServiceProtocol
    ) {
        self.client = client
        self.richTextProcessor = richTextProcessor
        self.postService = postService
    }

    // MARK: - Check-in Creation

    public func createCheckin(place: Place, customMessage _: String?, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        // Build structured location data
        let location = buildCheckinLocation(for: place)

        // Create check-in text (shorter, structured label)
        let checkinText = buildCheckinText(for: place)

        // Create check-in record
        let checkinRecord = ATProtoCheckinRecord(
            text: checkinText,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            location: location
        )

        let request = ATProtoCreateCheckinRequest(
            repo: credentials.did,
            record: checkinRecord
        )

        do {
            let response = try await client.createCheckin(request: request, credentials: credentials)
            print("✅ Successfully created check-in: \(response.uri)")
            return response
        } catch {
            print("❌ Failed to create check-in: \(error)")
            throw error
        }
    }

    public func createCheckinWithPost(place: Place, customMessage: String?, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        // Step 1: Create the check-in record
        let checkinResponse = try await createCheckin(place: place, customMessage: customMessage, credentials: credentials)

        // Step 2: Create a post that embeds the check-in and includes rich text
        let (postText, _) = richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)

        let postResponse = try await postService.createPost(
            text: postText,
            credentials: credentials,
            embedRecord: checkinResponse
        )

        print("✅ Successfully created check-in with post: \(postResponse.uri)")
        return postResponse
    }

    // MARK: - Private Methods

    private func buildCheckinLocation(for place: Place) -> CheckinLocation {
        let geo = CheckinGeoLocation(lat: place.latitude, lng: place.longitude)

        // Build address from OSM tags if available
        let address = buildAddress(from: place.tags)

        // Create URI for the place
        let placeURI = buildPlaceURI(for: place)

        let placeLocation = CheckinPlaceLocation(
            name: place.name,
            geo: geo,
            address: address,
            uri: placeURI
        )

        return .place(placeLocation)
    }

    private func buildAddress(from tags: [String: String]) -> CheckinAddress? {
        let streetAddress = buildStreetAddress(from: tags)
        let locality = tags["addr:city"] ?? tags["addr:locality"]
        let region = tags["addr:state"] ?? tags["addr:region"]
        let country = tags["addr:country"]
        let postalCode = tags["addr:postcode"] ?? tags["addr:postal_code"]

        // Only create address if we have at least one component
        if streetAddress != nil || locality != nil || region != nil || country != nil || postalCode != nil {
            return CheckinAddress(
                streetAddress: streetAddress,
                locality: locality,
                region: region,
                country: country,
                postalCode: postalCode
            )
        }

        return nil
    }

    private func buildStreetAddress(from tags: [String: String]) -> String? {
        var streetComponents: [String] = []

        if let housenumber = tags["addr:housenumber"] {
            streetComponents.append(housenumber)
        }

        if let street = tags["addr:street"] {
            streetComponents.append(street)
        }

        return streetComponents.isEmpty ? nil : streetComponents.joined(separator: " ")
    }

    private func buildPlaceURI(for place: Place) -> String {
        let elementType = switch place.elementType {
        case .node:
            "node"
        case .way:
            "way"
        case .relation:
            "relation"
        }

        return "https://www.openstreetmap.org/\(elementType)/\(place.elementId)"
    }

    private func buildCheckinText(for place: Place) -> String {
        // Create a shorter, more structured text for the check-in record itself
        var components: [String] = [place.name]

        // Add category if available
        if let category = place.category {
            components.append("(\(category))")
        }

        // Add location context if available from tags
        if let city = place.tags["addr:city"] ?? place.tags["addr:locality"] {
            components.append("in \(city)")
        }

        return components.joined(separator: " ")
    }
}
