//
//  LinkedInAutomationStore.swift
//  fsocial
//
//  Created by Mason Earl on 1/12/26.
//

import Foundation
import Combine

class LinkedInAutomationStore: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isRunning: Bool = false
    @Published var interests: [String] = []
    @Published var keywords: [String] = []
    @Published var maxConnectionsPerSession: Int = 10
    @Published var delayBetweenActions: Double = 2.0 // seconds
    @Published var connectionsMade: Int = 0
    @Published var lastRunDate: Date?
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let interestsKey = "linkedin.automation.interests"
    private let keywordsKey = "linkedin.automation.keywords"
    private let enabledKey = "linkedin.automation.enabled"
    private let maxConnectionsKey = "linkedin.automation.maxConnections"
    private let delayKey = "linkedin.automation.delay"
    private let connectionsMadeKey = "linkedin.automation.connectionsMade"
    private let lastRunKey = "linkedin.automation.lastRun"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        isEnabled = userDefaults.bool(forKey: enabledKey)
        interests = userDefaults.stringArray(forKey: interestsKey) ?? []
        keywords = userDefaults.stringArray(forKey: keywordsKey) ?? []
        maxConnectionsPerSession = userDefaults.integer(forKey: maxConnectionsKey)
        if maxConnectionsPerSession == 0 {
            maxConnectionsPerSession = 10 // default
        }
        delayBetweenActions = userDefaults.double(forKey: delayKey)
        if delayBetweenActions == 0 {
            delayBetweenActions = 2.0 // default
        }
        connectionsMade = userDefaults.integer(forKey: connectionsMadeKey)
        if let lastRunTimestamp = userDefaults.object(forKey: lastRunKey) as? Date {
            lastRunDate = lastRunTimestamp
        }
    }
    
    func saveSettings() {
        userDefaults.set(isEnabled, forKey: enabledKey)
        userDefaults.set(interests, forKey: interestsKey)
        userDefaults.set(keywords, forKey: keywordsKey)
        userDefaults.set(maxConnectionsPerSession, forKey: maxConnectionsKey)
        userDefaults.set(delayBetweenActions, forKey: delayKey)
        userDefaults.set(connectionsMade, forKey: connectionsMadeKey)
        if let lastRun = lastRunDate {
            userDefaults.set(lastRun, forKey: lastRunKey)
        }
    }
    
    func addInterest(_ interest: String) {
        let trimmed = interest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !interests.contains(trimmed) {
            interests.append(trimmed)
            saveSettings()
        }
    }
    
    func removeInterest(_ interest: String) {
        interests.removeAll { $0 == interest }
        saveSettings()
    }
    
    func addKeyword(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !keywords.contains(trimmed) {
            keywords.append(trimmed)
            saveSettings()
        }
    }
    
    func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        saveSettings()
    }
    
    func resetStats() {
        connectionsMade = 0
        lastRunDate = nil
        saveSettings()
    }
    
    func incrementConnections() {
        connectionsMade += 1
        lastRunDate = Date()
        saveSettings()
    }
}
