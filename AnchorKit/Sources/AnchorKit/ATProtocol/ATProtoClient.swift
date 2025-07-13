import Foundation

// MARK: - AT Protocol Client Protocol

@MainActor
public protocol ATProtoClientProtocol: Sendable {
    func login(request: ATProtoLoginRequest) async throws -> ATProtoLoginResponse
    func refresh(request: ATProtoRefreshRequest) async throws -> ATProtoRefreshResponse
    func createPost(request: ATProtoCreatePostRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse
    func createRecord(request: ATProtoCreateAddressRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse
    func createRecord(request: ATProtoCreateCheckinRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse
    func createCheckinWithAddress(
        text: String,
        address: CommunityAddressRecord,
        coordinates: GeoCoordinates,
        category: String?,
        categoryGroup: String?,
        categoryIcon: String?,
        credentials: AuthCredentialsProtocol
    ) async throws -> String
    func deleteRecord(repo: String, collection: String, rkey: String, credentials: AuthCredentialsProtocol) async throws
    func getRecord(uri: String, credentials: AuthCredentialsProtocol) async throws -> ATProtoGetRecordResponse
    func verifyStrongRef(_ strongRef: StrongRef, credentials: AuthCredentialsProtocol) async throws -> Bool
    func resolveCheckin(uri: String, credentials: AuthCredentialsProtocol) async throws -> ResolvedCheckin
}

// MARK: - AT Protocol Client Implementation

@MainActor
public final class ATProtoClient: ATProtoClientProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: String

    // MARK: - Initialization

    public init(baseURL: String = AnchorConfig.shared.blueskyPDSURL, session: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Authentication

    public func login(request: ATProtoLoginRequest) async throws -> ATProtoLoginResponse {
        let httpRequest = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.createSession",
            method: "POST",
            body: request
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoLoginResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func refresh(request: ATProtoRefreshRequest) async throws -> ATProtoRefreshResponse {
        let httpRequest = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.refreshSession",
            method: "POST",
            body: request
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoRefreshResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    // MARK: - Record Creation

    public func createPost(request: ATProtoCreatePostRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse {
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)

        // Debug response
        if response is HTTPURLResponse {}

        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func createRecord(request: ATProtoCreateAddressRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse {
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func createRecord(request: ATProtoCreateCheckinRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse {
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func createCheckinWithAddress(
        text: String,
        address: CommunityAddressRecord,
        coordinates: GeoCoordinates,
        category: String? = nil,
        categoryGroup: String? = nil,
        categoryIcon: String? = nil,
        credentials: AuthCredentialsProtocol
    ) async throws -> String {
        // Step 1: Create address record
        let addressRequest = ATProtoCreateAddressRequest(repo: credentials.did, record: address)
        let addressResponse = try await createRecord(request: addressRequest, credentials: credentials)

        // Step 2: Create checkin record with strongref
        let checkinRecord = CheckinRecord(
            text: text,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            addressRef: StrongRef(uri: addressResponse.uri, cid: addressResponse.cid),
            coordinates: coordinates,
            category: category,
            categoryGroup: categoryGroup,
            categoryIcon: categoryIcon
        )

        do {
            let checkinRequest = ATProtoCreateCheckinRequest(repo: credentials.did, record: checkinRecord)
            let checkinResponse = try await createRecord(request: checkinRequest, credentials: credentials)
            return checkinResponse.uri
        } catch {
            // Cleanup: Delete orphaned address record
            let addressRkey = extractRkey(from: addressResponse.uri)
            try? await deleteRecord(
                repo: credentials.did,
                collection: "community.lexicon.location.address",
                rkey: addressRkey,
                credentials: credentials
            )
            throw error
        }
    }

    public func deleteRecord(repo: String, collection: String, rkey: String, credentials: AuthCredentialsProtocol) async throws {
        struct DeleteRecordRequest: Codable {
            let repo: String
            let collection: String
            let rkey: String
        }

        let deleteRequest = DeleteRecordRequest(repo: repo, collection: collection, rkey: rkey)
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.deleteRecord",
            method: "POST",
            body: deleteRequest,
            accessToken: credentials.accessToken
        )

        let (_, response) = try await session.data(for: httpRequest)
        try validateResponse(response)
    }

    public func getRecord(uri: String, credentials: AuthCredentialsProtocol) async throws -> ATProtoGetRecordResponse {
        // Parse AT URI to extract components: at://did/collection/rkey
        let components = uri.components(separatedBy: "/")
        guard components.count >= 4,
              components[0] == "at:",
              components[1].isEmpty else {
            throw ATProtoError.invalidURL
        }

        let repo = components[2]
        let collection = components[3]
        let rkey = components[4]

        var urlComponents = URLComponents(string: baseURL + "/xrpc/com.atproto.repo.getRecord")!
        urlComponents.queryItems = [
            URLQueryItem(name: "repo", value: repo),
            URLQueryItem(name: "collection", value: collection),
            URLQueryItem(name: "rkey", value: rkey)
        ]

        guard let url = urlComponents.url else {
            throw ATProtoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AnchorConfig.shared.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoGetRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func verifyStrongRef(_ strongRef: StrongRef, credentials: AuthCredentialsProtocol) async throws -> Bool {
        do {
            let record = try await getRecord(uri: strongRef.uri, credentials: credentials)
            return record.cid == strongRef.cid
        } catch {
            // If we can't fetch the record, verification fails
            return false
        }
    }

    public func resolveCheckin(uri: String, credentials: AuthCredentialsProtocol) async throws -> ResolvedCheckin {
        // 1. Fetch checkin record
        let checkinResponse = try await getRecord(uri: uri, credentials: credentials)

        // 2. Decode checkin record from the response value
        let checkin = try JSONDecoder().decode(CheckinRecord.self, from: checkinResponse.value)

        // 3. Resolve address strongref
        let addressResponse = try await getRecord(uri: checkin.addressRef.uri, credentials: credentials)

        // 4. Verify content integrity
        let isVerified = addressResponse.cid == checkin.addressRef.cid

        // 5. Decode address record
        let address = try JSONDecoder().decode(CommunityAddressRecord.self, from: addressResponse.value)

        return ResolvedCheckin(checkin: checkin, address: address, isVerified: isVerified)
    }

    // MARK: - Private Methods

    private func buildRequest(
        endpoint: String,
        method: String,
        body: (some Codable)? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw ATProtoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AnchorConfig.shared.userAgent, forHTTPHeaderField: "User-Agent")

        if let body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw ATProtoError.decodingError(error)
            }
        }

        return request
    }

    private func buildAuthenticatedRequest(
        endpoint: String,
        method: String,
        body: (some Codable)? = nil,
        accessToken: String
    ) throws -> URLRequest {
        var request = try buildRequest(endpoint: endpoint, method: method, body: body)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ATProtoError.invalidResponse
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            throw ATProtoError.httpError(httpResponse.statusCode)
        }
    }

    private func extractRkey(from uri: String) -> String {
        // Extract rkey from AT URI format: at://did/collection/rkey
        let components = uri.components(separatedBy: "/")
        return components.last ?? ""
    }
}
