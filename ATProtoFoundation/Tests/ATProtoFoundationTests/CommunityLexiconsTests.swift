//
//  CommunityLexiconsTests.swift
//  ATProtoFoundation
//
//  Tests for community and Bluesky lexicon constants
//

import Foundation
import Testing
@testable import ATProtoFoundation

@Suite("Community Lexicons", .tags(.unit, .models))
struct CommunityLexiconsTests {

    // MARK: - Community Lexicon Constants

    @Test("Location geo lexicon constant")
    func locationGeoConstant() {
        #expect(CommunityLexicon.locationGeo == "community.lexicon.location.geo")
    }

    @Test("Location address lexicon constant")
    func locationAddressConstant() {
        #expect(CommunityLexicon.locationAddress == "community.lexicon.location.address")
    }

    // MARK: - Bluesky Lexicon Constants

    @Test("Feed post lexicon constant")
    func feedPostConstant() {
        #expect(BlueskyLexicon.feedPost == "app.bsky.feed.post")
    }

    @Test("Rich text link lexicon constant")
    func richTextLinkConstant() {
        #expect(BlueskyLexicon.richTextLink == "app.bsky.richtext.facet#link")
    }

    @Test("Rich text mention lexicon constant")
    func richTextMentionConstant() {
        #expect(BlueskyLexicon.richTextMention == "app.bsky.richtext.facet#mention")
    }

    @Test("Rich text tag lexicon constant")
    func richTextTagConstant() {
        #expect(BlueskyLexicon.richTextTag == "app.bsky.richtext.facet#tag")
    }

    // MARK: - Extensibility Tests

    @Test("Lexicon constants are stable strings")
    func lexiconConstantsAreStableStrings() {
        // These should never change - they're protocol identifiers
        let expectedCommunityGeo = "community.lexicon.location.geo"
        let expectedCommunityAddress = "community.lexicon.location.address"
        let expectedFeedPost = "app.bsky.feed.post"

        #expect(CommunityLexicon.locationGeo == expectedCommunityGeo)
        #expect(CommunityLexicon.locationAddress == expectedCommunityAddress)
        #expect(BlueskyLexicon.feedPost == expectedFeedPost)
    }
}
