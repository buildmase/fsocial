//
//  WebView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI
import WebKit

// MARK: - Shared Process Pool for Session Sharing
class WebViewProcessPool {
    static let shared = WKProcessPool()
}

// MARK: - WebView Coordinator
@Observable
class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var currentURL: URL?
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var isLoading: Bool = false
    var pageTitle: String = ""
    
    weak var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func goHome(url: URL) {
        webView?.load(URLRequest(url: url))
    }
    
    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView?.load(URLRequest(url: url))
    }
    
    func injectText(_ text: String) {
        // JavaScript to find active text field and insert text
        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        let javascript = """
        (function() {
            var activeElement = document.activeElement;
            if (activeElement && (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA' || activeElement.isContentEditable)) {
                if (activeElement.isContentEditable) {
                    activeElement.textContent = '\(escapedText)';
                    // Trigger input event
                    activeElement.dispatchEvent(new Event('input', { bubbles: true }));
                } else {
                    activeElement.value = '\(escapedText)';
                    activeElement.dispatchEvent(new Event('input', { bubbles: true }));
                }
                return true;
            }
            // Try to find any focused contenteditable div (common in modern social platforms)
            var editables = document.querySelectorAll('[contenteditable="true"]');
            for (var i = 0; i < editables.length; i++) {
                if (editables[i].offsetParent !== null) {
                    editables[i].focus();
                    editables[i].textContent = '\(escapedText)';
                    editables[i].dispatchEvent(new Event('input', { bubbles: true }));
                    return true;
                }
            }
            return false;
        })();
        """
        
        webView?.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                print("JavaScript injection error: \(error)")
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    nonisolated func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Task { @MainActor in
            self.isLoading = true
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.isLoading = false
            self.currentURL = webView.url
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.pageTitle = webView.title ?? ""
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.isLoading = false
        }
    }
}

// MARK: - WebView (NSViewRepresentable)
struct WebView: NSViewRepresentable {
    let url: URL
    let coordinator: WebViewCoordinator
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WebViewProcessPool.shared
        configuration.websiteDataStore = .default()
        
        // Enable JavaScript
        let preferences = WKPreferences()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        coordinator.webView = webView
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only reload if coordinator's webView is nil (initial load)
        if coordinator.webView == nil {
            coordinator.webView = nsView
        }
    }
}
