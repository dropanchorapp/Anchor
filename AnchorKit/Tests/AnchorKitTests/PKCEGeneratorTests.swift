//
//  PKCEGeneratorTests.swift
//  AnchorKitTests
//
//  Created by Tijs Teulings on 22/08/2025.
//

import Testing
@testable import AnchorKit
import Foundation
import CryptoKit

@Suite("PKCE Generator", .tags(.unit))
struct PKCEGeneratorTests {

    @Test("PKCE generation produces valid parameters")
    func pkceGenerationProducesValidParameters() {
        let pkce = PKCEGenerator.generatePKCE()
        
        // Verify code verifier length (RFC 7636: 43-128 characters)
        #expect(pkce.codeVerifier.count >= 43)
        #expect(pkce.codeVerifier.count <= 128)
        
        // Verify code verifier contains only allowed characters
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        #expect(pkce.codeVerifier.allSatisfy { allowedCharacters.contains($0.unicodeScalars.first!) })
        
        // Verify code challenge is valid base64url (without padding)
        #expect(!pkce.codeChallenge.contains("="))
        #expect(!pkce.codeChallenge.contains("+"))
        #expect(!pkce.codeChallenge.contains("/"))
        
        // Verify code challenge method
        #expect(pkce.codeChallengeMethod == "S256")
        
        // Verify code challenge is correct SHA256 hash
        let data = pkce.codeVerifier.data(using: .ascii)!
        let hash = SHA256.hash(data: data)
        let expectedChallenge = Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        #expect(pkce.codeChallenge == expectedChallenge)
    }
    
    @Test("PKCE generation produces unique values")
    func pkceGenerationProducesUniqueValues() {
        let pkce1 = PKCEGenerator.generatePKCE()
        let pkce2 = PKCEGenerator.generatePKCE()
        
        // Should generate different values each time
        #expect(pkce1.codeVerifier != pkce2.codeVerifier)
        #expect(pkce1.codeChallenge != pkce2.codeChallenge)
    }
}