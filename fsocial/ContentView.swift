//
//  ContentView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI
import AppKit

enum ViewMode {
    case browser
    case scheduler
    case composer
    case insights
    case settings
}

struct ContentView: View {
    @State private var selectedPlatform: Platform = .x
    @StateObject private var replyStore = QuickReplyStore()
    @StateObject private var scheduleStore = ScheduleStore()
    @StateObject private var draftStore = DraftStore()
    @StateObject private var hashtagStore = HashtagStore()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var aiService = AIService()
    @StateObject private var updateChecker = UpdateChecker()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var viewMode: ViewMode = .browser
    @State private var showUpdateAlert = false
    
    // Coordinators for each platform (keeps WebViews alive)
    @State private var coordinators: [Platform: WebViewCoordinator] = [:]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(
                selectedPlatform: $selectedPlatform,
                replyStore: replyStore,
                scheduleStore: scheduleStore,
                draftStore: draftStore,
                historyStore: historyStore,
                aiService: aiService,
                viewMode: $viewMode,
                currentCoordinator: coordinators[selectedPlatform],
                onReplySelected: handleReplySelected
            )
            
            Divider()
                .background(Color.appBorder)
            
            // Main Content Area
            ZStack {
                // Browser views
                ForEach(Platform.allCases) { platform in
                    BrowserView(
                        platform: platform,
                        coordinator: coordinator(for: platform)
                    )
                    .opacity(viewMode == .browser && selectedPlatform == platform ? 1 : 0)
                    .allowsHitTesting(viewMode == .browser && selectedPlatform == platform)
                }
                
                // Scheduler view
                if viewMode == .scheduler {
                    SchedulerView(scheduleStore: scheduleStore)
                        .transition(.opacity)
                }
                
                // Composer view
                if viewMode == .composer {
                    ComposerView(
                        draftStore: draftStore,
                        hashtagStore: hashtagStore,
                        historyStore: historyStore,
                        aiService: aiService,
                        onSwitchToPlatform: { platform in
                            selectedPlatform = platform
                            viewMode = .browser
                        }
                    )
                    .transition(.opacity)
                }
                
                // Insights view
                if viewMode == .insights {
                    InsightsView(
                        historyStore: historyStore,
                        hashtagStore: hashtagStore
                    )
                    .transition(.opacity)
                }
                
                // Settings view
                if viewMode == .settings {
                    SettingsView(
                        aiService: aiService,
                        updateChecker: updateChecker
                    )
                    .transition(.opacity)
                }
            }
        }
        .background(Color.appBackground)
        .toast(isShowing: $showToast, message: toastMessage)
        .onAppear {
            // Check for updates on launch
            updateChecker.checkForUpdates()
        }
        .onReceive(updateChecker.$updateAvailable) { available in
            if available {
                showUpdateAlert = true
            }
        }
        .sheet(isPresented: $showUpdateAlert) {
            UpdateAlertView(updateChecker: updateChecker, isPresented: $showUpdateAlert)
        }
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
