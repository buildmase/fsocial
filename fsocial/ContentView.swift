//
//  ContentView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedPlatform: Platform = .x
    @State private var replyStore = QuickReplyStore()
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Coordinators for each platform (keeps WebViews alive)
    @State private var coordinators: [Platform: WebViewCoordinator] = [:]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedPlatform: $selectedPlatform,
                replyStore: replyStore,
                onReplySelected: handleReplySelected
            )
            
            Divider()
                .background(Color.appBorder)
            
            // Browser Area
            ZStack {
                ForEach(Platform.allCases) { platform in
                    BrowserView(
                        platform: platform,
                        coordinator: coordinator(for: platform)
                    )
                    .opacity(selectedPlatform == platform ? 1 : 0)
                    .allowsHitTesting(selectedPlatform == platform)
                }
            }
        }
        .background(Color.appBackground)
        .toast(isShowing: $showToast, message: toastMessage)
    }
    
    // MARK: - Get or Create Coordinator
    private func coordinator(for platform: Platform) -> WebViewCoordinator {
        if let existing = coordinators[platform] {
            return existing
        }
        let newCoordinator = WebViewCoordinator()
        DispatchQueue.main.async {
            coordinators[platform] = newCoordinator
        }
        return newCoordinator
    }
    
    // MARK: - Handle Reply Selected
    private func handleReplySelected(_ text: String) {
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Try to inject into active text field
        if let currentCoordinator = coordinators[selectedPlatform] {
            currentCoordinator.injectText(text)
        }
        
        // Show toast
        toastMessage = "Copied!"
        withAnimation {
            showToast = true
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1400, height: 900)
}
