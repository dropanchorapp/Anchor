//
//  FeedMockData.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import Foundation
import AnchorKit

// MARK: - Shared Mock Data for Feed Posts

// Helper: mock AnchorAppViewCheckin
private func makeMockCheckin(id: String, authorDid: String, authorHandle: String, text: String, createdAt: Date, latitude: Double?, longitude: Double?, addressName: String?, distance: Double? = nil) -> AnchorAppViewCheckin {
    let isoDate = ISO8601DateFormatter().string(from: createdAt)
    let coords = (latitude != nil && longitude != nil) ? AnchorAppViewCoordinates(latitude: latitude!, longitude: longitude!) : nil
    let address = addressName != nil ? AnchorAppViewAddress(name: addressName) : nil
    return AnchorAppViewCheckin(
        id: id,
        uri: "at://\(authorDid)/app.bsky.feed.post/\(id)",
        author: AnchorAppViewAuthor(did: authorDid, handle: authorHandle),
        text: text,
        createdAt: isoDate,
        coordinates: coords,
        address: address,
        distance: distance
    )
}

public let sampleCoffeeShopPost: FeedPost = {
    let checkin = makeMockCheckin(
        id: "sample1234",
        authorDid: "did:plc:sample1234",
        authorHandle: "coffee.lover.bsky.social",
        text: "Great coffee and amazing atmosphere! Perfect spot for morning work sessions ☕️",
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        latitude: 37.7749,
        longitude: -122.4194,
        addressName: "Blue Bottle Coffee"
    )
    return FeedPost(
        id: checkin.id,
        author: FeedAuthor(
            did: checkin.author.did,
            handle: checkin.author.handle,
            displayName: nil,
            avatar: nil
        ),
        record: ATProtoRecord(
            text: checkin.text,
            createdAt: ISO8601DateFormatter().date(from: checkin.createdAt) ?? Date()
        ),
        coordinates: checkin.coordinates,
        address: checkin.address,
        distance: checkin.distance
    )
}()

public let sampleRestaurantPost: FeedPost = {
    let checkin = makeMockCheckin(
        id: "sample5678",
        authorDid: "did:plc:sample5678",
        authorHandle: "foodie.adventures.bsky.social",
        text: "Incredible dim sum! The har gow was perfectly steamed and the xiaolongbao had amazing broth 🥟",
        createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
        latitude: 37.7849,
        longitude: -122.4094,
        addressName: "Golden Dragon Restaurant"
    )
    return FeedPost(
        id: checkin.id,
        author: FeedAuthor(
            did: checkin.author.did,
            handle: checkin.author.handle,
            displayName: nil,
            avatar: nil
        ),
        record: ATProtoRecord(
            text: checkin.text,
            createdAt: ISO8601DateFormatter().date(from: checkin.createdAt) ?? Date()
        ),
        coordinates: checkin.coordinates,
        address: checkin.address,
        distance: checkin.distance
    )
}()

public let sampleClimbingPost: FeedPost = {
    let checkin = makeMockCheckin(
        id: "sample9999",
        authorDid: "did:plc:sample9999",
        authorHandle: "mountain.goat.bsky.social",
        text: "Sent my first 5.11a! The crimps were brutal but so worth it. Yosemite never disappoints 🧗‍♂️",
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        latitude: 37.8651,
        longitude: -119.5383,
        addressName: "El Capitan"
    )
    return FeedPost(
        id: checkin.id,
        author: FeedAuthor(
            did: checkin.author.did,
            handle: checkin.author.handle,
            displayName: nil,
            avatar: nil
        ),
        record: ATProtoRecord(
            text: checkin.text,
            createdAt: ISO8601DateFormatter().date(from: checkin.createdAt) ?? Date()
        ),
        coordinates: checkin.coordinates,
        address: checkin.address,
        distance: checkin.distance
    )
}()

public let allSamplePosts: [FeedPost] = [
    sampleCoffeeShopPost,
    sampleRestaurantPost,
    sampleClimbingPost
] 
