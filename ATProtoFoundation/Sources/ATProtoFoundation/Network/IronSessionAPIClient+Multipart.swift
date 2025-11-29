//
//  IronSessionAPIClient+Multipart.swift
//  AnchorKit
//
//  Multipart/form-data extension for IronSessionAPIClient
//

import Foundation

// MARK: - Multipart Form Data Extension

extension IronSessionAPIClient {

    /// Make authenticated multipart/form-data request
    ///
    /// Handles multipart form data uploads with the same authentication logic
    /// as regular requests (proactive refresh, 401 retry, exponential backoff).
    ///
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - fields: Text fields as key-value pairs
    ///   - files: File attachments to upload
    /// - Returns: Response data
    /// - Throws: API errors if request fails
    public func authenticatedMultipartRequest(
        path: String,
        fields: [String: String] = [:],
        files: [MultipartFile] = []
    ) async throws -> Data {
        // Verify authentication
        guard (await credentialsStorage.load()) != nil else {
            throw AuthenticationError.invalidCredentials("Authentication required")
        }

        // Build multipart request
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = config.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart body
        var body = Data()

        // Add text fields
        for (key, value) in fields {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data(value.utf8))
            body.append(Data("\r\n".utf8))
        }

        // Add file fields
        for file in files {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\r\n".utf8))
            body.append(Data("Content-Type: \(file.contentType)\r\n\r\n".utf8))
            body.append(file.data)
            body.append(Data("\r\n".utf8))
        }

        // Close boundary
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        logger.log(
            "🌐 Making authenticated multipart request to \(path), body size: \(body.count) bytes",
            level: .debug,
            category: .network
        )

        // Use the same authenticated request logic (proactive refresh, 401 retry)
        // Send request directly since we already built the full request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError("Invalid response type")
        }

        // Handle 401 with retry logic
        if httpResponse.statusCode == 401 {
            logger.log(
                "🔐 Received 401 on multipart request, attempting refresh and retry",
                level: .debug,
                category: .network
            )

            // Attempt session refresh
            try await refreshSession()

            // Retry the request once after refresh
            let (retryData, retryResponse) = try await session.data(for: request)

            guard let retryHTTPResponse = retryResponse as? HTTPURLResponse else {
                throw AuthenticationError.networkError("Invalid response type on retry")
            }

            guard 200...299 ~= retryHTTPResponse.statusCode else {
                let statusCode = retryHTTPResponse.statusCode
                throw AuthenticationError.apiError(statusCode, "HTTP \(statusCode)")
            }

            return retryData
        }

        guard 200...299 ~= httpResponse.statusCode else {
            let statusCode = httpResponse.statusCode
            throw AuthenticationError.apiError(statusCode, "HTTP \(statusCode)")
        }

        return data
    }
}
