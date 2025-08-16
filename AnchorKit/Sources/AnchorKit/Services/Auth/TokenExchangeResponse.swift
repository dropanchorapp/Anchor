//
//  TokenExchangeResponse.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

/// Token exchange response from backend (OAuth 2.1 compliant)
public struct TokenExchangeResponse: Codable {
    public let access_token: String
    public let refresh_token: String
    public let expires_in: Int  // OAuth 2.1 standard: lifetime in seconds
    public let token_type: String
    public let scope: String
    public let did: String
    public let handle: String
    public let pds_url: String
    public let session_id: String
    public let display_name: String?
    public let avatar: String?
}
