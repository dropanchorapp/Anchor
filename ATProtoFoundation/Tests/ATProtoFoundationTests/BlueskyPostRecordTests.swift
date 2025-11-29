//
//  BlueskyPostRecordTests.swift
//  ATProtoFoundation
//
//  Tests for BlueskyPostRecord, ATProtoFacet, and ATProtoFeature types
//

import Foundation
import Testing
@testable import ATProtoFoundation

@Suite("BlueskyPostRecord", .tags(.unit, .models))
struct BlueskyPostRecordTests {

    // MARK: - BlueskyPostRecord Creation Tests

    @Test("Record with text only")
    func recordWithTextOnly() {
        let record = BlueskyPostRecord(text: "Hello, world!")

        #expect(record.text == "Hello, world!")
        #expect(record.formattedText == "Hello, world!")
        #expect(record.facets.isEmpty)
        #expect(record.type == "app.bsky.feed.post")
    }

    @Test("Record with custom type")
    func recordWithCustomType() {
        let record = BlueskyPostRecord(
            text: "Test",
            createdAt: Date(),
            type: "custom.type"
        )

        #expect(record.type == "custom.type")
    }

    @Test("Record with facets")
    func recordWithFacets() {
        let facet = ATProtoFacet(
            index: 0...4,
            feature: .link("https://example.com")
        )
        let record = BlueskyPostRecord(
            text: "Visit https://example.com",
            facets: [facet]
        )

        #expect(record.facets.count == 1)
        #expect(!record.formattedText.isEmpty)
    }

    // MARK: - ATProtoFacet Tests

    @Test("Facet index range")
    func facetIndexRange() {
        let facet = ATProtoFacet(
            index: 10...20,
            feature: .hashtag("test")
        )

        #expect(facet.index == 10...20)
        #expect(facet.index.lowerBound == 10)
        #expect(facet.index.upperBound == 20)
    }

    // MARK: - ATProtoFeature Tests

    @Test("Link feature URL")
    func linkFeatureURL() {
        let feature = ATProtoFeature.link("https://example.com")
        #expect(feature.url == "https://example.com")
    }

    @Test("Mention feature URL")
    func mentionFeatureURL() {
        let feature = ATProtoFeature.mention("did:plc:abc123")
        #expect(feature.url == "https://bsky.app/profile/did:plc:abc123")
    }

    @Test("Hashtag feature URL")
    func hashtagFeatureURL() {
        let feature = ATProtoFeature.hashtag("climbing")
        #expect(feature.url == "https://bsky.app/search?q=%23climbing")
    }

    @Test("Hashtag with special characters URL encoded")
    func hashtagWithSpecialCharsURLEncoded() {
        let feature = ATProtoFeature.hashtag("rock&roll")
        #expect(feature.url == "https://bsky.app/search?q=%23rock%26roll")
    }

    // MARK: - Markdown Formatting Tests

    @Test("Text with no facets returns unchanged")
    func textWithNoFacetsReturnsUnchanged() {
        let record = BlueskyPostRecord(text: "Simple text with no links")
        #expect(record.formattedText == "Simple text with no links")
    }

    @Test("Single link converts to markdown")
    func singleLinkConvertsToMarkdown() {
        let text = "Check out https://example.com for more"
        let facet = ATProtoFacet(
            index: 10...28,
            feature: .link("https://example.com")
        )
        let record = BlueskyPostRecord(text: text, facets: [facet])

        #expect(record.formattedText.contains("[https://example.com](https://example.com)"))
    }

    @Test("Hashtag converts to markdown with search URL")
    func hashtagConvertsToMarkdown() {
        let text = "Love this #climbing session"
        let facet = ATProtoFacet(
            index: 10...18,
            feature: .hashtag("climbing")
        )
        let record = BlueskyPostRecord(text: text, facets: [facet])

        #expect(record.formattedText.contains("[#climbing](https://bsky.app/search?q=%23climbing)"))
    }

    // MARK: - Hashable & Equatable Tests

    @Test("ATProtoFeature equality")
    func featureEquality() {
        let link1 = ATProtoFeature.link("https://example.com")
        let link2 = ATProtoFeature.link("https://example.com")
        let link3 = ATProtoFeature.link("https://other.com")

        #expect(link1 == link2)
        #expect(link1 != link3)
    }

    @Test("ATProtoFacet equality")
    func facetEquality() {
        let facet1 = ATProtoFacet(index: 0...10, feature: .link("https://example.com"))
        let facet2 = ATProtoFacet(index: 0...10, feature: .link("https://example.com"))
        let facet3 = ATProtoFacet(index: 0...10, feature: .link("https://other.com"))

        #expect(facet1 == facet2)
        #expect(facet1 != facet3)
    }
}
