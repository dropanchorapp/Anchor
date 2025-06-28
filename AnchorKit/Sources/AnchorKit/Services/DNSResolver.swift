import Foundation

/// DNS-over-HTTPS resolver for AT Protocol DNS queries
public final class DNSResolver: @unchecked Sendable {
    
    /// Resolve DNS TXT record using DNS-over-HTTPS with fallback
    public static func resolveTXTRecord(dnsName: String) async -> String? {
        // Try primary DNS provider first
        if let result = await tryDNSProvider(dnsName: dnsName, baseURL: AnchorConfig.shared.primaryDNSOverHTTPSURL) {
            return result
        }
        
        // Fallback to secondary DNS provider
        print("🔄 [DNSResolver] Primary DNS failed, trying fallback provider")
        return await tryDNSProvider(dnsName: dnsName, baseURL: AnchorConfig.shared.fallbackDNSOverHTTPSURL)
    }
    
    /// Try a specific DNS-over-HTTPS provider
    private static func tryDNSProvider(dnsName: String, baseURL: String) async -> String? {
        let dohURL = "\(baseURL)?name=\(dnsName)&type=TXT"
        let providerName = baseURL.contains("cloudflare") ? "Cloudflare" : 
                          baseURL.contains("google") ? "Google" : "DNS"
        
        do {
            guard let url = URL(string: dohURL) else { 
                print("❌ [DNSResolver] Invalid DOH URL: \(dohURL)")
                return nil 
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = AnchorConfig.shared.dnsTimeoutSeconds
            
            print("🌐 [DNSResolver] Querying \(providerName) DNS via DOH: \(dohURL)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [DNSResolver] DOH response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("❌ [DNSResolver] \(providerName) DNS error: \(errorData)")
                    }
                    return nil
                }
            }
            
            // Parse DNS JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [DNSResolver] Failed to parse DOH JSON response")
                return nil
            }
            
            guard let answers = json["Answer"] as? [[String: Any]] else {
                print("🔍 [DNSResolver] No DNS answers found for \(dnsName)")
                return nil
            }
            
            print("🔍 [DNSResolver] Found \(answers.count) DNS answers")
            
            // Look for TXT records containing DID
            for answer in answers {
                if let type = answer["type"] as? Int,
                   type == 16, // TXT record type
                   let data = answer["data"] as? String {
                    
                    print("🔍 [DNSResolver] Found TXT record: \(data)")
                    
                    // Parse DID from TXT record (format: "did=did:plc:...")
                    let cleanData = data.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    if cleanData.hasPrefix("did=") {
                        let did = String(cleanData.dropFirst(4)) // Remove "did=" prefix
                        print("✅ [DNSResolver] Extracted DID from DNS: \(did)")
                        return did
                    }
                }
            }
            
            print("❌ [DNSResolver] No valid DID found in TXT records for \(dnsName)")
            return nil
            
        } catch {
            print("❌ [DNSResolver] Error resolving DNS TXT via \(providerName) DOH: \(error)")
            return nil
        }
    }
} 