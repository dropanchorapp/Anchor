//
//  TimelineModelsTests.swift
//  ATProtoFoundation
//
//  Tests for Timeline API response models
//

import Foundation
import Testing
@testable import ATProtoFoundation

@Suite("Timeline Models", .tags(.unit, .models))
struct TimelineModelsTests {

    // MARK: - TimelineRecord Tests

    @Test("TimelineRecord decodes from JSON")
    func timelineRecordDecodesFromJSON() throws {
        let json = """
        {
            "text": "Hello world",
            "createdAt": "2025-01-15T12:00:00Z",
            "$type": "app.bsky.feed.post"
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(TimelineRecord.self, from: json)

        #expect(record.text == "Hello world")
        #expect(record.createdAt == "2025-01-15T12:00:00Z")
        #expect(record.type == "app.bsky.feed.post")
        #expect(record.facets == nil)
    }

    @Test("TimelineRecord decodes with facets")
    func timelineRecordDecodesWithFacets() throws {
        let json = """
        {
            "text": "Check out https://example.com",
            "createdAt": "2025-01-15T12:00:00Z",
            "$type": "app.bsky.feed.post",
            "facets": [
                {
                    "index": { "byteStart": 10, "byteEnd": 29 },
                    "features": [
                        { "$type": "app.bsky.richtext.facet#link", "uri": "https://example.com" }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(TimelineRecord.self, from: json)

        #expect(record.facets?.count == 1)
        #expect(record.facets?[0].index.byteStart == 10)
        #expect(record.facets?[0].index.byteEnd == 29)
        #expect(record.facets?[0].features.count == 1)
    }

    // MARK: - FacetIndex Tests

    @Test("FacetIndex decodes byte positions")
    func facetIndexDecodesBytePositions() throws {
        let json = """
        { "byteStart": 0, "byteEnd": 19 }
        """.data(using: .utf8)!

        let index = try JSONDecoder().decode(FacetIndex.self, from: json)

        #expect(index.byteStart == 0)
        #expect(index.byteEnd == 19)
    }

    // MARK: - FacetFeature Tests

    @Test("FacetFeature decodes link type")
    func facetFeatureDecodesLink() throws {
        let json = """
        {
            "$type": "app.bsky.richtext.facet#link",
            "uri": "https://example.com"
        }
        """.data(using: .utf8)!

        let feature = try JSONDecoder().decode(FacetFeature.self, from: json)

        #expect(feature.type == "app.bsky.richtext.facet#link")
        #expect(feature.uri == "https://example.com")
        #expect(feature.did == nil)
        #expect(feature.tag == nil)
    }

    @Test("FacetFeature decodes mention type")
    func facetFeatureDecodesMention() throws {
        let json = """
        {
            "$type": "app.bsky.richtext.facet#mention",
            "did": "did:plc:abc123"
        }
        """.data(using: .utf8)!

        let feature = try JSONDecoder().decode(FacetFeature.self, from: json)

        #expect(feature.type == "app.bsky.richtext.facet#mention")
        #expect(feature.did == "did:plc:abc123")
        #expect(feature.uri == nil)
        #expect(feature.tag == nil)
    }

    @Test("FacetFeature decodes hashtag type")
    func facetFeatureDecodesHashtag() throws {
        let json = """
        {
            "$type": "app.bsky.richtext.facet#tag",
            "tag": "climbing"
        }
        """.data(using: .utf8)!

        let feature = try JSONDecoder().decode(FacetFeature.self, from: json)

        #expect(feature.type == "app.bsky.richtext.facet#tag")
        #expect(feature.tag == "climbing")
        #expect(feature.uri == nil)
        #expect(feature.did == nil)
    }

    // MARK: - BlueskyPostRecord Conversion Tests

    @Test("BlueskyPostRecord initializes from TimelineRecord")
    func blueskyPostRecordFromTimelineRecord() {
        let timelineRecord = TimelineRecord(
            text: "Test post",
            createdAt: "2025-01-15T12:00:00Z",
            type: "app.bsky.feed.post",
            facets: nil
        )

        let record = BlueskyPostRecord(from: timelineRecord)

        #expect(record.text == "Test post")
        #expect(record.type == "app.bsky.feed.post")
        #expect(record.facets.isEmpty)
    }

    @Test("BlueskyPostRecord converts facets from TimelineRecord")
    func blueskyPostRecordConvertsFacets() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 0, byteEnd: 19),
            features: [
                FacetFeature(
                    type: "app.bsky.richtext.facet#link",
                    uri: "https://example.com",
                    did: nil,
                    tag: nil
                )
            ]
        )
        let timelineRecord = TimelineRecord(
            text: "https://example.com is great",
            createdAt: "2025-01-15T12:00:00Z",
            type: "app.bsky.feed.post",
            facets: [timelineFacet]
        )

        let record = BlueskyPostRecord(from: timelineRecord)

        #expect(record.facets.count == 1)
        if case .link(let url) = record.facets[0].feature {
            #expect(url == "https://example.com")
        } else {
            Issue.record("Expected link feature")
        }
    }

    // MARK: - ATProtoFacet Conversion Tests

    @Test("ATProtoFacet from link TimelineFacet")
    func atProtoFacetFromLinkTimelineFacet() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 5, byteEnd: 24),
            features: [
                FacetFeature(
                    type: "app.bsky.richtext.facet#link",
                    uri: "https://example.com",
                    did: nil,
                    tag: nil
                )
            ]
        )

        let facet = ATProtoFacet(from: timelineFacet)

        #expect(facet != nil)
        // Note: byteEnd is exclusive, so 5...24 in API becomes 5...23 in Swift range
        #expect(facet?.index == 5...23)
        if case .link(let url) = facet?.feature {
            #expect(url == "https://example.com")
        } else {
            Issue.record("Expected link feature")
        }
    }

    @Test("ATProtoFacet from mention TimelineFacet")
    func atProtoFacetFromMentionTimelineFacet() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 0, byteEnd: 15),
            features: [
                FacetFeature(
                    type: "app.bsky.richtext.facet#mention",
                    uri: nil,
                    did: "did:plc:user123",
                    tag: nil
                )
            ]
        )

        let facet = ATProtoFacet(from: timelineFacet)

        #expect(facet != nil)
        if case .mention(let did) = facet?.feature {
            #expect(did == "did:plc:user123")
        } else {
            Issue.record("Expected mention feature")
        }
    }

    @Test("ATProtoFacet from hashtag TimelineFacet")
    func atProtoFacetFromHashtagTimelineFacet() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 0, byteEnd: 8),
            features: [
                FacetFeature(
                    type: "app.bsky.richtext.facet#tag",
                    uri: nil,
                    did: nil,
                    tag: "swift"
                )
            ]
        )

        let facet = ATProtoFacet(from: timelineFacet)

        #expect(facet != nil)
        if case .hashtag(let tag) = facet?.feature {
            #expect(tag == "swift")
        } else {
            Issue.record("Expected hashtag feature")
        }
    }

    @Test("ATProtoFacet returns nil for unsupported type")
    func atProtoFacetReturnsNilForUnsupportedType() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 0, byteEnd: 10),
            features: [
                FacetFeature(
                    type: "unsupported.type",
                    uri: nil,
                    did: nil,
                    tag: nil
                )
            ]
        )

        let facet = ATProtoFacet(from: timelineFacet)

        #expect(facet == nil)
    }

    @Test("ATProtoFacet returns nil for invalid index range")
    func atProtoFacetReturnsNilForInvalidIndexRange() {
        let timelineFacet = TimelineFacet(
            index: FacetIndex(byteStart: 20, byteEnd: 10), // End before start
            features: [
                FacetFeature(
                    type: "app.bsky.richtext.facet#link",
                    uri: "https://example.com",
                    did: nil,
                    tag: nil
                )
            ]
        )

        let facet = ATProtoFacet(from: timelineFacet)

        #expect(facet == nil)
    }
}
