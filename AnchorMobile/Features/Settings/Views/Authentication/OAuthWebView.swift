//
//  OAuthWebView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 10/08/2025.
//

import SwiftUI
import WebKit

struct OAuthWebView: UIViewRepresentable {
    let url: URL
    let onAuthComplete: (OAuthResult) -> Void
    let onCancel: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Set custom user agent to identify as mobile app
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "AnchorApp/1.0 (iOS)"
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: OAuthWebView
        
        init(_ parent: OAuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Check if this is our custom URL scheme callback
            if url.scheme == "anchor-app" && url.host == "auth-callback" {
                handleAuthCallback(url: url)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onAuthComplete(.failure(OAuthError.networkError(error)))
        }
        
        private func handleAuthCallback(url: URL) {
            // Just pass the callback URL to AnchorKit - let it handle all the OAuth logic
            parent.onAuthComplete(.success(url))
        }
    }
}

// MARK: - Supporting Types

enum OAuthResult {
    case success(URL) // Just pass the callback URL to AnchorKit
    case failure(OAuthError)
}

enum OAuthError: LocalizedError {
    case networkError(Error)
    case invalidCallback
    case missingParameters
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidCallback:
            return "Invalid authentication callback"
        case .missingParameters:
            return "Missing required authentication parameters"
        case .cancelled:
            return "Authentication was cancelled"
        }
    }
}

// MARK: - Preview
#Preview {
    OAuthWebView(
        url: URL(string: "https://dropanchor.app/mobile-auth")!,
        onAuthComplete: { result in
            print("Auth result: \(result)")
        },
        onCancel: {
            print("Auth cancelled")
        }
    )
}
