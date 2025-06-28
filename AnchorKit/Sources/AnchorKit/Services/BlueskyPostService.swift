import Foundation

// MARK: - Bluesky Post Service Protocol

@MainActor
public protocol BlueskyPostServiceProtocol {
    func createPost(text: String, credentials: AuthCredentialsProtocol, embedRecord: ATProtoCreateRecordResponse?) async throws -> ATProtoCreateRecordResponse
}

// MARK: - Bluesky Post Service

@MainActor
public final class BlueskyPostService: BlueskyPostServiceProtocol {
    // MARK: - Properties

    private let client: ATProtoClientProtocol
    private let richTextProcessor: RichTextProcessorProtocol

    // MARK: - Initialization

    public init(client: ATProtoClientProtocol, richTextProcessor: RichTextProcessorProtocol) {
        self.client = client
        self.richTextProcessor = richTextProcessor
    }

    // MARK: - Post Creation

    public func createPost(text: String, credentials: AuthCredentialsProtocol, embedRecord: ATProtoCreateRecordResponse? = nil) async throws -> ATProtoCreateRecordResponse {
        // Detect facets in the text
        let facets = richTextProcessor.detectFacets(in: text)

        // Create post record
        var postRecord = ATProtoPostRecord(
            text: text,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            facets: facets.isEmpty ? nil : facets,
            embed: nil
        )

        // Add embed if provided
        if let embedRecord {
            postRecord = ATProtoPostRecord(
                text: text,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                facets: facets.isEmpty ? nil : facets,
                embed: ATProtoPostEmbed(record: ATProtoEmbedRecord(uri: embedRecord.uri, cid: embedRecord.cid))
            )
        }

        let request = ATProtoCreatePostRequest(
            repo: credentials.did,
            record: postRecord
        )

        return try await client.createPost(request: request, credentials: credentials)
    }
}
