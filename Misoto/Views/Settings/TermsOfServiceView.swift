//
//  TermsOfServiceView.swift
//  Misoto
//
//  Displays Apple's Standard End User License Agreement (EULA)
//

import SwiftUI
import WebKit

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    var body: some View {
        NavigationView {
            ZStack {
                // Web View displaying Apple's Standard EULA
                EULAWebView(url: eulaURL, isLoading: $isLoading)
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle(LocalizedString("Terms of Use (EULA)", comment: "EULA title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - EULA Web View

struct EULAWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Disable JavaScript if desired (optional, but keeps it more read-only)
        // configuration.preferences.javaScriptEnabled = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Disable user interaction for editing/selection (read-only)
        webView.allowsBackForwardNavigationGestures = false
        webView.isUserInteractionEnabled = true // Allow scrolling
        
        // Set navigation delegate
        webView.navigationDelegate = context.coordinator
        
        // Load the EULA URL
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed - URL is fixed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: EULAWebView
        
        init(_ parent: EULAWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("❌ Error loading EULA: \(error.localizedDescription)")
        }
        
        // Prevent navigation to other pages - keep it on the EULA page only
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow navigation only to the EULA URL or its fragments
            if let targetURL = navigationAction.request.url {
                let targetString = targetURL.absoluteString
                let eulaString = parent.url.absoluteString
                
                // Allow if it's the same domain/page (including fragments)
                if targetString.hasPrefix(eulaString) || targetString == eulaString {
                    decisionHandler(.allow)
                } else {
                    // Block navigation to other pages - keep it read-only on EULA page
                    decisionHandler(.cancel)
                }
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

#Preview {
    TermsOfServiceView()
}
