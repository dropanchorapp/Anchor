import XCTest
@testable import AnchorKit

final class BlueskyServiceTests: XCTestCase {
    
    var blueskyService: BlueskyService!
    
    override func setUp() {
        super.setUp()
        blueskyService = BlueskyService()
    }
    
    override func tearDown() {
        blueskyService = nil
        super.tearDown()
    }
    
    // MARK: - Rich Text Facets Tests
    
    func testBuildCheckInTextWithFacets_basicPlace() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Boulder Central",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing", "name": "Boulder Central"]
        )
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: nil)
        
        // Then
        let expectedText = "Dropped ⚓ at Boulder Central #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 3, "Should have link facet and two hashtag facets")
        
        // Verify link facet for venue name
        let linkFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link = feature { return true }
                return false
            }
        }
        XCTAssertNotNil(linkFacet, "Should have link facet for venue name")
        
        if let linkFacet = linkFacet {
            // Venue name starts at position 12 ("Dropped ⚓ at ".utf8.count)
            let expectedLinkStart = "Dropped ⚓ at ".utf8.count
            let expectedLinkEnd = "Dropped ⚓ at Boulder Central".utf8.count
            
            XCTAssertEqual(linkFacet.index.byteStart, expectedLinkStart)
            XCTAssertEqual(linkFacet.index.byteEnd, expectedLinkEnd)
            
            // Check the URL
            if case .link(let uri) = linkFacet.features.first {
                XCTAssertEqual(uri, "https://www.openstreetmap.org/way/123456")
            } else {
                XCTFail("Link facet should contain URL")
            }
        }
        
        // Verify first hashtag facet (#checkin)
        let checkinHashtagFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "checkin"
                }
                return false
            }
        }
        XCTAssertNotNil(checkinHashtagFacet, "Should have #checkin hashtag facet")
        
        if let checkinHashtagFacet = checkinHashtagFacet {
            // #checkin hashtag starts after "Dropped ⚓ at Boulder Central "
            let textBeforeFirstHashtag = "Dropped ⚓ at Boulder Central "
            let expectedHashtagStart = textBeforeFirstHashtag.utf8.count
            let expectedHashtagEnd = (textBeforeFirstHashtag + "#checkin").utf8.count
            
            XCTAssertEqual(checkinHashtagFacet.index.byteStart, expectedHashtagStart)
            XCTAssertEqual(checkinHashtagFacet.index.byteEnd, expectedHashtagEnd)
            
            if case .tag(let tag) = checkinHashtagFacet.features.first {
                XCTAssertEqual(tag, "checkin")
            } else {
                XCTFail("Hashtag facet should contain tag")
            }
        }
        
        // Verify second hashtag facet (#dropanchor)
        let dropanchorHashtagFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "dropanchor"
                }
                return false
            }
        }
        XCTAssertNotNil(dropanchorHashtagFacet, "Should have #dropanchor hashtag facet")
        
        if let dropanchorHashtagFacet = dropanchorHashtagFacet {
            // #dropanchor hashtag starts after "Dropped ⚓ at Boulder Central #checkin "
            let textBeforeSecondHashtag = "Dropped ⚓ at Boulder Central #checkin "
            let expectedHashtagStart = textBeforeSecondHashtag.utf8.count
            let expectedHashtagEnd = (textBeforeSecondHashtag + "#dropanchor").utf8.count
            
            XCTAssertEqual(dropanchorHashtagFacet.index.byteStart, expectedHashtagStart)
            XCTAssertEqual(dropanchorHashtagFacet.index.byteEnd, expectedHashtagEnd)
            
            if case .tag(let tag) = dropanchorHashtagFacet.features.first {
                XCTAssertEqual(tag, "dropanchor")
            } else {
                XCTFail("Hashtag facet should contain tag")
            }
        }
    }
    
    func testBuildCheckInTextWithFacets_withCustomMessage() {
        // Given
        let place = Place(
            elementType: .node,
            elementId: 789012,
            name: "Rock Gym",
            latitude: 40.7128,
            longitude: -74.0060,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Great climbing session today!"
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        let expectedText = "Great climbing session today!\n\nDropped ⚓ at Rock Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 3)
        
        // Verify link facet accounting for custom message prefix
        let linkFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link = feature { return true }
                return false
            }
        }
        XCTAssertNotNil(linkFacet)
        
        if let linkFacet = linkFacet {
            let textBeforeVenue = "Great climbing session today!\n\nDropped ⚓ at "
            let expectedLinkStart = textBeforeVenue.utf8.count
            let expectedLinkEnd = (textBeforeVenue + "Rock Gym").utf8.count
            
            XCTAssertEqual(linkFacet.index.byteStart, expectedLinkStart)
            XCTAssertEqual(linkFacet.index.byteEnd, expectedLinkEnd)
            
            if case .link(let uri) = linkFacet.features.first {
                XCTAssertEqual(uri, "https://www.openstreetmap.org/node/789012")
            }
        }
    }
    
    func testBuildCheckInTextWithFacets_unicodeCharacters() {
        // Given - Test with venue name containing unicode characters
        let place = Place(
            elementType: .way,
            elementId: 555444,
            name: "Café Escalade 🧗‍♂️",
            latitude: 48.8566,
            longitude: 2.3522,
            tags: ["leisure": "climbing", "name": "Café Escalade 🧗‍♂️"]
        )
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: nil)
        
        // Then
        let expectedText = "Dropped ⚓ at Café Escalade 🧗‍♂️ #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        
        // Verify facets handle unicode properly
        let linkFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link = feature { return true }
                return false
            }
        }
        XCTAssertNotNil(linkFacet)
        
        if let linkFacet = linkFacet {
            // Unicode characters require proper UTF-8 byte counting
            let textBeforeVenue = "Dropped ⚓ at "
            let venueName = "Café Escalade 🧗‍♂️"
            
            let expectedLinkStart = textBeforeVenue.utf8.count
            let expectedLinkEnd = (textBeforeVenue + venueName).utf8.count
            
            XCTAssertEqual(linkFacet.index.byteStart, expectedLinkStart)
            XCTAssertEqual(linkFacet.index.byteEnd, expectedLinkEnd)
        }
    }
    
    func testBuildCheckInTextWithFacets_relationElementType() {
        // Given
        let place = Place(
            elementType: .relation,
            elementId: 111222,
            name: "Climbing Area Complex",
            latitude: 39.7392,
            longitude: -104.9903,
            tags: ["leisure": "climbing"]
        )
        
        // When
        let (_, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: nil)
        
        // Then
        XCTAssertEqual(facets.count, 3)
        
        let linkFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri.contains("relation/111222")
                }
                return false
            }
        }
        XCTAssertNotNil(linkFacet, "Should generate correct URL for relation element type")
    }
    
    func testBuildCheckInTextWithFacets_emptyCustomMessage() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        
        // When - Empty custom message should be treated as nil
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: "")
        
        // Then - Should be same as no custom message
        let expectedText = "Dropped ⚓ at Test Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 3)
    }
    
    func testBuildCheckInTextWithFacets_longVenueName() {
        // Given - Test with a very long venue name
        let longName = "The Really Really Long Climbing Gymnasium and Fitness Center of Excellence"
        let place = Place(
            elementType: .way,
            elementId: 999888,
            name: longName,
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: nil)
        
        // Then
        XCTAssertTrue(text.contains(longName), "Should include full venue name")
        XCTAssertEqual(facets.count, 3)
        
        // Verify link facet covers the entire venue name
        let linkFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link = feature { return true }
                return false
            }
        }
        XCTAssertNotNil(linkFacet)
        
        if let linkFacet = linkFacet {
            let textBeforeVenue = "Dropped ⚓ at "
            let expectedLinkStart = textBeforeVenue.utf8.count
            let expectedLinkEnd = (textBeforeVenue + longName).utf8.count
            
            XCTAssertEqual(linkFacet.index.byteStart, expectedLinkStart)
            XCTAssertEqual(linkFacet.index.byteEnd, expectedLinkEnd)
        }
    }
    
    // MARK: - User Message Facet Detection Tests
    
    func testDetectFacetsInUserMessage_urls() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Check out https://example.com and visit www.test.co.uk for more info!"
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        let expectedText = "Check out https://example.com and visit www.test.co.uk for more info!\n\nDropped ⚓ at Test Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 5, "Should have 2 URL facets + 1 venue link + 2 hashtag facets")
        
        // Verify first URL facet (https://example.com)
        let firstUrlFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri == "https://example.com"
                }
                return false
            }
        }
        XCTAssertNotNil(firstUrlFacet, "Should have facet for https://example.com")
        
        if let firstUrlFacet = firstUrlFacet {
            let expectedStart = "Check out ".utf8.count
            let expectedEnd = "Check out https://example.com".utf8.count
            XCTAssertEqual(firstUrlFacet.index.byteStart, expectedStart)
            XCTAssertEqual(firstUrlFacet.index.byteEnd, expectedEnd)
        }
        
        // Verify second URL facet (www.test.co.uk -> https://www.test.co.uk)
        let secondUrlFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri == "https://www.test.co.uk"
                }
                return false
            }
        }
        XCTAssertNotNil(secondUrlFacet, "Should have facet for www.test.co.uk")
        
        if let secondUrlFacet = secondUrlFacet {
            let textBeforeSecondUrl = "Check out https://example.com and visit "
            let expectedStart = textBeforeSecondUrl.utf8.count
            let expectedEnd = (textBeforeSecondUrl + "www.test.co.uk").utf8.count
            XCTAssertEqual(secondUrlFacet.index.byteStart, expectedStart)
            XCTAssertEqual(secondUrlFacet.index.byteEnd, expectedEnd)
        }
    }
    
    func testDetectFacetsInUserMessage_hashtags() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Having a great time #climbing and #bouldering today! #fitness"
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        let expectedText = "Having a great time #climbing and #bouldering today! #fitness\n\nDropped ⚓ at Test Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 6, "Should have 3 user hashtag facets + 1 venue link + 2 post hashtag facets")
        
        // Verify #climbing facet
        let climbingFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "climbing"
                }
                return false
            }
        }
        XCTAssertNotNil(climbingFacet, "Should have facet for #climbing")
        
        if let climbingFacet = climbingFacet {
            let expectedStart = "Having a great time ".utf8.count
            let expectedEnd = "Having a great time #climbing".utf8.count
            XCTAssertEqual(climbingFacet.index.byteStart, expectedStart)
            XCTAssertEqual(climbingFacet.index.byteEnd, expectedEnd)
        }
        
        // Verify #bouldering facet
        let boulderingFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "bouldering"
                }
                return false
            }
        }
        XCTAssertNotNil(boulderingFacet, "Should have facet for #bouldering")
        
        // Verify #fitness facet
        let fitnessFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "fitness"
                }
                return false
            }
        }
        XCTAssertNotNil(fitnessFacet, "Should have facet for #fitness")
    }
    
    func testDetectFacetsInUserMessage_mentions() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Climbing with @alice.bsky.social and @bob.test today!"
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        let expectedText = "Climbing with @alice.bsky.social and @bob.test today!\n\nDropped ⚓ at Test Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 5, "Should have 2 mention facets + 1 venue link + 2 hashtag facets")
        
        // Verify @alice.bsky.social facet
        let aliceFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .mention(let did) = feature {
                    return did == "alice.bsky.social" // Note: In real implementation, this would be resolved to a DID
                }
                return false
            }
        }
        XCTAssertNotNil(aliceFacet, "Should have facet for @alice.bsky.social")
        
        if let aliceFacet = aliceFacet {
            let expectedStart = "Climbing with ".utf8.count
            let expectedEnd = "Climbing with @alice.bsky.social".utf8.count
            XCTAssertEqual(aliceFacet.index.byteStart, expectedStart)
            XCTAssertEqual(aliceFacet.index.byteEnd, expectedEnd)
        }
        
        // Verify @bob.test facet
        let bobFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .mention(let did) = feature {
                    return did == "bob.test"
                }
                return false
            }
        }
        XCTAssertNotNil(bobFacet, "Should have facet for @bob.test")
    }
    
    func testDetectFacetsInUserMessage_mixedContent() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Great session with @friend.bsky.social! Check out https://example.com #climbing #fun"
        
        // When
        let (_, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        XCTAssertEqual(facets.count, 7, "Should have 1 mention + 1 URL + 2 user hashtags + 1 venue link + 2 post hashtags")
        
        // Verify all facets are present and non-overlapping
        let sortedFacets = facets.sorted { $0.index.byteStart < $1.index.byteStart }
        for i in 0..<(sortedFacets.count - 1) {
            XCTAssertLessThanOrEqual(sortedFacets[i].index.byteEnd, sortedFacets[i + 1].index.byteStart,
                                   "Facets should not overlap")
        }
    }
    
    func testDetectFacetsInUserMessage_urlWithPunctuation() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Check this out: https://example.com! And this (https://test.com)."
        
        // When
        let (_, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        // Should have URL facets that exclude trailing punctuation
        let firstUrlFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri == "https://example.com"
                }
                return false
            }
        }
        XCTAssertNotNil(firstUrlFacet, "Should detect first URL without exclamation mark")
        
        let secondUrlFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri == "https://test.com"
                }
                return false
            }
        }
        XCTAssertNotNil(secondUrlFacet, "Should detect second URL without closing parenthesis and period")
    }
    
    func testDetectFacetsInUserMessage_invalidContent() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "Invalid @mention.invalid and #123numbers and not-a-url.fake"
        
        // When
        let (_, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        // Should only have venue link and post hashtags, no user message facets
        XCTAssertEqual(facets.count, 3, "Should only have venue link and 2 post hashtags")
        
        // Verify no mention facets for invalid handles
        let mentionFacets = facets.filter { facet in
            facet.features.contains { feature in
                if case .mention = feature { return true }
                return false
            }
        }
        XCTAssertEqual(mentionFacets.count, 0, "Should not detect invalid mentions")
    }
    
    func testDetectFacetsInUserMessage_unicodeContent() {
        // Given
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing"]
        )
        let customMessage = "🧗‍♂️ Great climb! #escalade 🇫🇷 https://café.example.com"
        
        // When
        let (_, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        // Should handle unicode characters properly in byte indexing
        let urlFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .link(let uri) = feature {
                    return uri == "https://café.example.com"
                }
                return false
            }
        }
        XCTAssertNotNil(urlFacet, "Should detect URL with unicode characters")
        
        let hashtagFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "escalade"
                }
                return false
            }
        }
        XCTAssertNotNil(hashtagFacet, "Should detect hashtag with unicode in surrounding text")
    }
    
    func testDetectFacetsInUserMessage_mentionWithComma() {
        // Given - Test mention followed by comma (edge case)
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: [:]
        )
        let customMessage = "Oh noes we're doing a recorded test where we use some #facets such as a mention @tijs.org, i hope this will work…"
        
        // When
        let (text, facets) = blueskyService.buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        
        // Then
        let expectedText = "Oh noes we're doing a recorded test where we use some #facets such as a mention @tijs.org, i hope this will work…\n\nDropped ⚓ at Test Gym #checkin #dropanchor"
        XCTAssertEqual(text, expectedText)
        XCTAssertEqual(facets.count, 5, "Should have 1 hashtag + 1 mention + 1 venue link + 2 post hashtags")
        
        // Verify mention facet is detected correctly
        let mentionFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .mention(let did) = feature {
                    return did == "tijs.org"
                }
                return false
            }
        }
        XCTAssertNotNil(mentionFacet, "Should detect @tijs.org mention even with trailing comma")
        
        // Verify hashtag facet is detected correctly
        let hashtagFacet = facets.first { facet in
            facet.features.contains { feature in
                if case .tag(let tag) = feature {
                    return tag == "facets"
                }
                return false
            }
        }
        XCTAssertNotNil(hashtagFacet, "Should detect #facets hashtag")
    }
    
    // MARK: - Facets Structure Tests
    
    func testRichTextFacetStructure() {
        // Given
        let byteRange = ByteRange(byteStart: 0, byteEnd: 10)
        let linkFeature = RichTextFeature.link(uri: "https://example.com")
        let facet = RichTextFacet(index: byteRange, features: [linkFeature])
        
        // Then
        XCTAssertEqual(facet.index.byteStart, 0)
        XCTAssertEqual(facet.index.byteEnd, 10)
        XCTAssertEqual(facet.features.count, 1)
        
        if case .link(let uri) = facet.features.first {
            XCTAssertEqual(uri, "https://example.com")
        } else {
            XCTFail("Should be link feature")
        }
    }
    
    func testRichTextFacetFeatureTypes() {
        // Test link feature
        let linkFeature = RichTextFeature.link(uri: "https://openstreetmap.org")
        if case .link(let uri) = linkFeature {
            XCTAssertEqual(uri, "https://openstreetmap.org")
        } else {
            XCTFail("Should be link feature")
        }
        
        // Test tag feature
        let tagFeature = RichTextFeature.tag(tag: "checkin")
        if case .tag(let tag) = tagFeature {
            XCTAssertEqual(tag, "checkin")
        } else {
            XCTFail("Should be tag feature")
        }
        
        // Test mention feature
        let mentionFeature = RichTextFeature.mention(did: "did:plc:test123")
        if case .mention(let did) = mentionFeature {
            XCTAssertEqual(did, "did:plc:test123")
        } else {
            XCTFail("Should be mention feature")
        }
    }
} 