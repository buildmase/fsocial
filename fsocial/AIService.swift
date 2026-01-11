//
//  AIService.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import Foundation
import SwiftUI
import Combine

class AIService: ObservableObject {
    private let apiKeyKey = "com.fsocial.openai.apikey"
    
    @Published var isLoading = false
    @Published var suggestedReplies: [String] = []
    @Published var lastError: String?
    @Published var hasAPIKey: Bool = false
    
    init() {
        hasAPIKey = getAPIKey() != nil
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: apiKeyKey)
        hasAPIKey = true
    }
    
    func getAPIKey() -> String? {
        UserDefaults.standard.string(forKey: apiKeyKey)
    }
    
    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        hasAPIKey = false
    }
    
    // MARK: - Generate Smart Replies
    
    func generateReplies(for content: String, platform: Platform) {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            lastError = "No API key configured"
            return
        }
        
        guard !content.isEmpty else {
            suggestedReplies = []
            return
        }
        
        isLoading = true
        lastError = nil
        
        let prompt = buildPrompt(content: content, platform: platform)
        
        Task {
            do {
                let replies = try await callOpenAI(prompt: prompt, apiKey: apiKey)
                DispatchQueue.main.async {
                    self.suggestedReplies = replies
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func buildPrompt(content: String, platform: Platform) -> String {
        let platformName = platform.rawValue
        let characterLimit = platform.characterLimit
        
        return """
        You are a social media expert helping generate engaging replies for \(platformName).
        
        The user is viewing this content:
        "\(content.prefix(1000))"
        
        Generate 4 short, authentic reply options that:
        - Are relevant to the content above
        - Sound natural and conversational (not robotic)
        - Are appropriate for \(platformName)
        - Are under \(min(characterLimit, 280)) characters each
        - Include a mix of: supportive, insightful, funny, or engaging tones
        
        Return ONLY the 4 replies, one per line, no numbering or bullets.
        """
    }
    
    private func callOpenAI(prompt: String, apiKey: String) async throws -> [String] {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300,
            "temperature": 0.8
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }
        
        // Parse the response into individual replies
        let replies = content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(4)
            .map { String($0) }
        
        return Array(replies)
    }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .parseError:
            return "Failed to parse response"
        }
    }
}
