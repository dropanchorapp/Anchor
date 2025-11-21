@testable import ATProtoFoundation
import Foundation
import Foundation
import Testing

@Suite("AT Protocol Models", .tags(.models))
struct ATProtoModelsTests {
    // MARK: - StrongRef Tests

    @Test("StrongRef creation with valid URI and CID")
    func strongRefCreation() throws {
        // Given
        let uri = "at://did:plc:test123/app.dropanchor.checkin/abc123"
        let cid = "bafyreid1234567890"

        // When
        let strongRef = StrongRef(uri: uri, cid: cid)

        // Then
        #expect(strongRef.uri == uri)
        #expect(strongRef.cid == cid)
    }

    @Test("StrongRef Codable conformance")
    func strongRefCodableConformance() throws {
        // Given
        let strongRef = StrongRef(
            uri: "at://did:plc:test123/app.dropanchor.checkin/abc123",
            cid: "bafyreid1234567890"
        )

        // When: Encode to JSON
        let jsonData = try JSONEncoder().encode(strongRef)
        let decoded = try JSONDecoder().decode(StrongRef.self, from: jsonData)

        // Then: Should round-trip correctly
        #expect(decoded.uri == strongRef.uri)
        #expect(decoded.cid == strongRef.cid)
    }

    // MARK: - GeoCoordinates Tests

    @Test("GeoCoordinates creation with Double values")
    func geoCoordinatesCreation() throws {
        // Given
        let lat = 37.7749
        let lng = -122.4194

        // When
        let coordinates = GeoCoordinates(latitude: lat, longitude: lng)

        // Then
        #expect(coordinates.latitude == "37.7749")
        #expect(coordinates.longitude == "-122.4194")
        #expect(coordinates.type == "community.lexicon.location.geo")
    }

    @Test("GeoCoordinates Codable conformance")
    func geoCoordinatesCodableConformance() throws {
        // Given
        let coordinates = GeoCoordinates(latitude: 37.7749, longitude: -122.4194)

        // When: Encode to JSON
        let jsonData = try JSONEncoder().encode(coordinates)
        let decoded = try JSONDecoder().decode(GeoCoordinates.self, from: jsonData)

        // Then: Should round-trip correctly
        #expect(decoded.latitude == coordinates.latitude)
        #expect(decoded.longitude == coordinates.longitude)
        #expect(decoded.type == coordinates.type)
    }

    // MARK: - CommunityAddressRecord Tests

    @Test("CommunityAddressRecord creation with all fields")
    func communityAddressRecordCreation() throws {
        // Given/When
        let address = CommunityAddressRecord(
            name: "Test Climbing Gym",
            street: "123 Main St",
            locality: "San Francisco",
            region: "CA",
            country: "US",
            postalCode: "94102"
        )

        // Then
        #expect(address.name == "Test Climbing Gym")
        #expect(address.street == "123 Main St")
        #expect(address.locality == "San Francisco")
        #expect(address.region == "CA")
        #expect(address.country == "US")
        #expect(address.postalCode == "94102")
        #expect(address.type == "community.lexicon.location.address")
    }

    @Test("CommunityAddressRecord creation with minimal fields")
    func communityAddressRecordMinimalCreation() throws {
        // Given/When
        let address = CommunityAddressRecord(name: "Test Place")

        // Then
        #expect(address.name == "Test Place")
        #expect(address.street == nil)
        #expect(address.locality == nil)
        #expect(address.region == nil)
        #expect(address.country == nil)
        #expect(address.postalCode == nil)
        #expect(address.type == "community.lexicon.location.address")
    }

    // CheckinRecord and ResolvedCheckin tests removed as they belong to AnchorKit

    // MARK: - Rich Text Tests

    @Test("RichTextFacet creation")
    func richTextFacetCreation() throws {
        // Given
        let byteRange = ByteRange(byteStart: 0, byteEnd: 10)
        let linkFeature = RichTextFeature.link(uri: "https://example.com")

        // When
        let facet = RichTextFacet(index: byteRange, features: [linkFeature])

        // Then
        #expect(facet.index.byteStart == 0)
        #expect(facet.index.byteEnd == 10)
        #expect(facet.features.count == 1)
    }

    @Test("RichTextFeature link encoding")
    func richTextFeatureLinkEncoding() throws {
        // Given
        let feature = RichTextFeature.link(uri: "https://example.com")

        // When: Encode to JSON
        let jsonData = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(RichTextFeature.self, from: jsonData)

        // Then
        if case let .link(uri) = decoded {
            #expect(uri == "https://example.com")
        } else {
            #expect(Bool(false), "Expected link feature")
        }
    }

    @Test("RichTextFeature mention encoding")
    func richTextFeatureMentionEncoding() throws {
        // Given
        let feature = RichTextFeature.mention(did: "did:plc:test123")

        // When: Encode to JSON
        let jsonData = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(RichTextFeature.self, from: jsonData)

        // Then
        if case let .mention(did) = decoded {
            #expect(did == "did:plc:test123")
        } else {
            #expect(Bool(false), "Expected mention feature")
        }
    }

    @Test("RichTextFeature tag encoding")
    func richTextFeatureTagEncoding() throws {
        // Given
        let feature = RichTextFeature.tag(tag: "climbing")

        // When: Encode to JSON
        let jsonData = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(RichTextFeature.self, from: jsonData)

        // Then
        if case let .tag(tag) = decoded {
            #expect(tag == "climbing")
        } else {
            #expect(Bool(false), "Expected tag feature")
        }
    }

    // MARK: - Error Tests

    // CheckinError tests removed as they belong to AnchorKit

    @Test("ATProtoError equality")
    func atProtoErrorEquality() throws {
        // Given
        let error1 = ATProtoError.httpError(404)
        let error2 = ATProtoError.httpError(404)
        let error3 = ATProtoError.httpError(500)

        // Then
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
