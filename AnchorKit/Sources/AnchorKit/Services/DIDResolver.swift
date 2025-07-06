import Foundation

/// DID resolution service for AT Protocol
public final class DIDResolver: @unchecked Sendable {

    /// Resolve a handle to its DID
    /// - Parameter handle: User handle (e.g., "user.bsky.social")
    /// - Returns: DID string or nil if resolution fails
    public static func resolveHandleToDID(_ handle: String) async -> String? {
        // Try DNS-based resolution first
        if let did = await resolveDIDViaDNS(handle) {
            return did
        }

        // Fallback to HTTP well-known resolution
        return await resolveDIDViaHTTP(handle)
    }

    /// Resolve DID to PDS endpoint
    /// - Parameter did: DID string (e.g., "did:plc:...")
    /// - Returns: PDS URL or nil if resolution fails
    public static func resolveDIDToPDS(_ did: String) async -> String? {
        // Resolve DID document to get PDS service endpoint
        let url = "https://plc.directory/\(did)"

        do {
            guard let requestURL = URL(string: url) else {
                print("❌ [DIDResolver] Invalid DID directory URL: \(url)")
                return nil
            }

            print("🌐 [DIDResolver] Fetching DID document from: \(url)")
            let (data, response) = try await URLSession.shared.data(from: requestURL)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [DIDResolver] DID directory response status: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("❌ [DIDResolver] DID directory error: \(errorData)")
                    }
                    return nil
                }
            }

            // Parse DID document
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [DIDResolver] Failed to parse DID document JSON")
                return nil
            }

            print("📄 [DIDResolver] Parsing DID document for services")

            // Extract PDS service endpoint
            guard let services = json["service"] as? [[String: Any]] else {
                print("❌ [DIDResolver] No services found in DID document")
                return nil
            }

            for service in services {
                if let type = service["type"] as? String,
                   type == "AtprotoPersonalDataServer",
                   let serviceEndpoint = service["serviceEndpoint"] as? String {
                    print("✅ [DIDResolver] Found PDS endpoint: \(serviceEndpoint)")
                    return serviceEndpoint
                }
            }

            print("❌ [DIDResolver] No AtprotoPersonalDataServer service found in DID document")
            return nil

        } catch {
            print("❌ [DIDResolver] Error resolving DID to PDS: \(error)")
            return nil
        }
    }

    // MARK: - Private Methods

    private static func resolveDIDViaDNS(_ handle: String) async -> String? {
        // DNS TXT record resolution for _atproto.{handle}
        let components = handle.split(separator: ".")
        guard components.count >= 2 else { return nil }

        let domain = components.dropFirst().joined(separator: ".")
        let dnsName = "_atproto.\(domain)"

        print("🔍 [DIDResolver] Resolving DNS TXT record for: \(dnsName)")

        // Use DNS-over-HTTPS for cross-platform compatibility
        return await DNSResolver.resolveTXTRecord(dnsName: dnsName)
    }

    private static func resolveDIDViaHTTP(_ handle: String) async -> String? {
        let components = handle.split(separator: ".")
        guard components.count >= 2 else { return nil }

        let domain = components.dropFirst().joined(separator: ".")
        let url = "https://\(domain)/.well-known/atproto-did"

        do {
            guard let requestURL = URL(string: url) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: requestURL)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
