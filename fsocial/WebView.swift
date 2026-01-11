//
//  WebView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI
import WebKit
import Combine

// MARK: - Shared Process Pool for Session Sharing
class WebViewProcessPool {
    static let shared = WKProcessPool()
}

// MARK: - WebView Coordinator
class WebViewCoordinator: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var currentURL: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var pageTitle: String = ""
    
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
        // Modern platforms like X use Draft.js editors - we need special handling
        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let javascript = """
        (function() {
            var text = '\(escapedText)';
            
            // Helper to dispatch input events properly
            function dispatchInputEvents(element) {
                element.dispatchEvent(new Event('focus', { bubbles: true }));
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
            }
            
            // Try execCommand first (works for contenteditable)
            function tryExecCommand(element) {
                element.focus();
                // Select all existing content first
                var selection = window.getSelection();
                var range = document.createRange();
                range.selectNodeContents(element);
                selection.removeAllRanges();
                selection.addRange(range);
                // Insert the text
                var success = document.execCommand('insertText', false, text);
                if (success) {
                    dispatchInputEvents(element);
                    return true;
                }
                return false;
            }
            
            // Handle standard input/textarea
            function handleStandardInput(element) {
                element.focus();
                element.value = text;
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            
            // Handle contenteditable (React/Draft.js style)
            function handleContentEditable(element) {
                element.focus();
                
                // Try execCommand first
                if (tryExecCommand(element)) {
                    return true;
                }
                
                // Fallback: use innerHTML with proper React event simulation
                element.innerHTML = '<span data-text="true">' + text + '</span>';
                dispatchInputEvents(element);
                
                // Also try to trigger React's internal handlers
                var nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value')?.set;
                if (nativeInputValueSetter) {
                    var hiddenTextarea = element.querySelector('textarea') || element.closest('[data-testid]')?.querySelector('textarea');
                    if (hiddenTextarea) {
                        nativeInputValueSetter.call(hiddenTextarea, text);
                        hiddenTextarea.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                }
                
                return true;
            }
            
            // Check active element first
            var activeElement = document.activeElement;
            if (activeElement) {
                if (activeElement.tagName === 'TEXTAREA' || activeElement.tagName === 'INPUT') {
                    return handleStandardInput(activeElement);
                }
                if (activeElement.isContentEditable || activeElement.getAttribute('contenteditable') === 'true') {
                    return handleContentEditable(activeElement);
                }
            }
            
            // X/Twitter specific: find the compose box
            var xCompose = document.querySelector('[data-testid="tweetTextarea_0"]') || 
                           document.querySelector('[data-testid="tweetTextarea_0_label"]')?.querySelector('[contenteditable="true"]') ||
                           document.querySelector('[aria-label="Post text"]') ||
                           document.querySelector('[aria-label="Tweet text"]') ||
                           document.querySelector('[role="textbox"][contenteditable="true"]');
            if (xCompose) {
                return handleContentEditable(xCompose);
            }
            
            // Instagram/Threads: find comment box
            var instaComment = document.querySelector('textarea[aria-label*="comment"]') ||
                               document.querySelector('textarea[placeholder*="comment"]') ||
                               document.querySelector('form textarea');
            if (instaComment) {
                return handleStandardInput(instaComment);
            }
            
            // LinkedIn: find message/post box
            var linkedinBox = document.querySelector('[contenteditable="true"][role="textbox"]') ||
                              document.querySelector('.ql-editor') ||
                              document.querySelector('[data-placeholder]');
            if (linkedinBox) {
                return handleContentEditable(linkedinBox);
            }
            
            // Generic fallback: find any visible contenteditable or textarea
            var editables = document.querySelectorAll('[contenteditable="true"], textarea:not([hidden])');
            for (var i = 0; i < editables.length; i++) {
                var el = editables[i];
                if (el.offsetParent !== null && el.offsetHeight > 0) {
                    if (el.tagName === 'TEXTAREA') {
                        return handleStandardInput(el);
                    } else {
                        return handleContentEditable(el);
                    }
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
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.currentURL = webView.url
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.pageTitle = webView.title ?? ""
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

// MARK: - WebView (NSViewRepresentable)
struct WebView: NSViewRepresentable {
    let url: URL
    @ObservedObject var coordinator: WebViewCoordinator
    
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
