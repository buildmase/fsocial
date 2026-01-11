//
//  ComposerView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI
import AppKit
import AVKit

struct ComposerView: View {
    @ObservedObject var draftStore: DraftStore
    @ObservedObject var hashtagStore: HashtagStore
    @ObservedObject var historyStore: HistoryStore
    @ObservedObject var aiService: AIService
    var onSwitchToPlatform: (Platform) -> Void
    
    @State private var showingMediaPicker = false
    @State private var showingSaveDraftAlert = false
    @State private var showingPostFlow = false
    @State private var currentPostingPlatform: Platform?
    @State private var selectedHashtags: [String] = []
    @State private var showHashtagPicker = false
    
    // AI Assistant
    @State private var aiPrompt = ""
    @State private var aiSuggestions: [String] = []
    @State private var isAILoading = false
    @State private var showAIAssistant = true
    @AppStorage("composer.aiAssistantCollapsed") private var aiAssistantCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Color.appBorder)
            
            // Main Content
            HStack(spacing: 0) {
                // Composer Area
                composerArea
                
                Divider()
                    .background(Color.appBorder)
                
                // Drafts Sidebar
                draftsSidebar
                    .frame(width: 250)
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showingPostFlow) {
            PostFlowSheet(
                draftStore: draftStore,
                historyStore: historyStore,
                onSwitchToPlatform: onSwitchToPlatform
            )
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Create Post")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
            
            Spacer()
            
            // Character count per selected platform
            characterCountIndicator
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    draftStore.saveDraft()
                } label: {
                    Text("Save Draft")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(Color.appTextMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appSecondary)
                        .cornerRadius(AppDimensions.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(draftStore.currentDraft.isEmpty)
                
                Button {
                    showingPostFlow = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                        Text("Post")
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(draftStore.currentDraft.isEmpty ? Color.appAccent.opacity(0.5) : Color.appAccent)
                    .cornerRadius(AppDimensions.borderRadius)
                }
                .buttonStyle(.plain)
                .disabled(draftStore.currentDraft.isEmpty)
            }
        }
        .padding(AppDimensions.padding)
        .background(Color.appBackground)
    }
    
    // MARK: - Character Count Indicator
    private var characterCountIndicator: some View {
        HStack(spacing: 12) {
            let contentLength = draftStore.currentDraft.content.count + selectedHashtags.joined(separator: " ").count
            
            ForEach(draftStore.currentDraft.platforms) { platform in
                let remaining = platform.characterLimit - contentLength
                let isOver = remaining < 0
                
                HStack(spacing: 4) {
                    Image(systemName: platform.iconName)
                        .font(.system(size: 10))
                    Text("\(remaining)")
                        .font(AppTypography.sectionLabel)
                }
                .foregroundStyle(isOver ? Color.red : (remaining < 50 ? Color.orange : Color.appTextMuted))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isOver ? Color.red.opacity(0.1) : Color.appSecondary)
                .cornerRadius(AppDimensions.borderRadius)
            }
        }
    }
    
    // MARK: - Composer Area
    private var composerArea: some View {
        ScrollView {
            VStack(spacing: 16) {
                // AI Assistant Section
                aiAssistantSection
                
                // Platform Selection
                platformSelection
                
                // Content Editor
                contentEditor
                
                // Hashtag Section
                hashtagSection
                
                // Media Section
                mediaSection
                
                // Tips Section
                tipsSection
            }
            .padding(AppDimensions.padding)
        }
    }
    
    // MARK: - AI Assistant Section
    private var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Collapsible Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    aiAssistantCollapsed.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: aiAssistantCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextMuted)
                        .frame(width: 12)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appAccent)
                    
                    Text("AI ASSISTANT")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                    
                    Spacer()
                    
                    if !aiService.hasAPIKey {
                        Text("No API key")
                            .font(AppTypography.sectionLabel)
                            .foregroundStyle(Color.appTextMuted.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)
            
            if !aiAssistantCollapsed {
                if !aiService.hasAPIKey {
                    // No API key message
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextMuted)
                        Text("Add an API key in the sidebar to use AI assistant")
                            .font(AppTypography.body)
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSecondary.opacity(0.5))
                    .cornerRadius(AppDimensions.borderRadius)
                } else {
                    // AI Input
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Ask AI to help write your post...", text: $aiPrompt)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .foregroundColor(Color.appText)
                                .padding(10)
                                .background(Color.appSecondary)
                                .cornerRadius(AppDimensions.borderRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                                .onSubmit {
                                    generateAIContent()
                                }
                            
                            Button {
                                generateAIContent()
                            } label: {
                                if isAILoading {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(aiPrompt.isEmpty ? Color.appTextMuted : Color.appAccent)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(aiPrompt.isEmpty || isAILoading)
                        }
                        
                        // Quick prompts
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                QuickPromptButton(text: "Write a post about...") {
                                    aiPrompt = "Write a post about "
                                }
                                QuickPromptButton(text: "Make it more engaging") {
                                    if !draftStore.currentDraft.content.isEmpty {
                                        aiPrompt = "Make this more engaging: \(draftStore.currentDraft.content.prefix(200))"
                                        generateAIContent()
                                    }
                                }
                                QuickPromptButton(text: "Add a hook") {
                                    if !draftStore.currentDraft.content.isEmpty {
                                        aiPrompt = "Add a compelling hook to this: \(draftStore.currentDraft.content.prefix(200))"
                                        generateAIContent()
                                    }
                                }
                                QuickPromptButton(text: "Shorten it") {
                                    if !draftStore.currentDraft.content.isEmpty {
                                        aiPrompt = "Make this shorter and punchier: \(draftStore.currentDraft.content.prefix(300))"
                                        generateAIContent()
                                    }
                                }
                            }
                        }
                        
                        // AI Suggestions
                        if !aiSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggestions")
                                    .font(AppTypography.sectionLabel)
                                    .foregroundStyle(Color.appTextMuted)
                                
                                ForEach(aiSuggestions.indices, id: \.self) { index in
                                    AISuggestionRow(
                                        text: aiSuggestions[index],
                                        onUse: {
                                            draftStore.currentDraft.content = aiSuggestions[index]
                                        },
                                        onAppend: {
                                            if draftStore.currentDraft.content.isEmpty {
                                                draftStore.currentDraft.content = aiSuggestions[index]
                                            } else {
                                                draftStore.currentDraft.content += "\n\n" + aiSuggestions[index]
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(12)
                            .background(Color.appSecondary.opacity(0.3))
                            .cornerRadius(AppDimensions.borderRadius)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Generate AI Content
    private func generateAIContent() {
        guard !aiPrompt.isEmpty, aiService.hasAPIKey else { return }
        
        isAILoading = true
        
        let platform = draftStore.currentDraft.platforms.first ?? .x
        let prompt = buildContentPrompt(userRequest: aiPrompt, platform: platform)
        
        // Use the AI service to generate content
        Task {
            do {
                let suggestions = try await generateWithAI(prompt: prompt)
                DispatchQueue.main.async {
                    self.aiSuggestions = suggestions
                    self.isAILoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAILoading = false
                }
            }
        }
    }
    
    private func buildContentPrompt(userRequest: String, platform: Platform) -> String {
        return """
        You're a social media content creator. Write post content for \(platform.rawValue).
        
        User request: \(userRequest)
        
        Character limit: \(platform.characterLimit)
        
        Write 3 different post options. Each should be:
        - Under the character limit
        - Engaging and authentic
        - NO emojis
        - Natural, human voice
        
        Just the 3 posts, one per line. No labels or numbers.
        """
    }
    
    private func generateWithAI(prompt: String) async throws -> [String] {
        guard let apiKey = aiService.getAPIKey() else {
            throw AIError.apiError("No API key")
        }
        
        let url: URL
        var request: URLRequest
        let body: [String: Any]
        
        switch aiService.selectedProvider {
        case .claude:
            url = URL(string: "https://api.anthropic.com/v1/messages")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            body = [
                "model": "claude-sonnet-4-20250514",
                "max_tokens": 500,
                "messages": [["role": "user", "content": prompt]]
            ]
            
        case .openai:
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            body = [
                "model": "gpt-4o-mini",
                "messages": [["role": "user", "content": prompt]],
                "max_tokens": 500
            ]
            
        case .grok:
            url = URL(string: "https://api.x.ai/v1/chat/completions")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            body = [
                "model": "grok-beta",
                "messages": [["role": "user", "content": prompt]],
                "max_tokens": 500
            ]
            
        case .gemini:
            url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            body = [
                "contents": [["parts": [["text": prompt]]]],
                "generationConfig": ["maxOutputTokens": 500]
            ]
            
        case .ollama:
            let urlString = apiKey.hasSuffix("/") ? "\(apiKey)api/generate" : "\(apiKey)/api/generate"
            url = URL(string: urlString)!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            body = [
                "model": "llama3.2",
                "prompt": prompt,
                "stream": false
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse response based on provider
        let text: String
        switch aiService.selectedProvider {
        case .claude:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let first = content.first,
                  let t = first["text"] as? String else {
                throw AIError.parseError
            }
            text = t
            
        case .openai, .grok:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let t = message["content"] as? String else {
                throw AIError.parseError
            }
            text = t
            
        case .gemini:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let first = candidates.first,
                  let content = first["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let t = firstPart["text"] as? String else {
                throw AIError.parseError
            }
            text = t
            
        case .ollama:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let t = json["response"] as? String else {
                throw AIError.parseError
            }
            text = t
        }
        
        // Parse into separate suggestions
        return text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line -> String in
                var cleaned = line
                if let range = cleaned.range(of: #"^[\d]+[.\)]\s*"#, options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                if cleaned.hasPrefix("- ") { cleaned.removeFirst(2) }
                if cleaned.hasPrefix("* ") { cleaned.removeFirst(2) }
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty && $0.count > 10 }
            .prefix(3)
            .map { String($0) }
    }
    
    // MARK: - Platform Selection
    private var platformSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POST TO")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                ForEach(Platform.allCases) { platform in
                    ComposerPlatformToggle(
                        platform: platform,
                        isSelected: draftStore.currentDraft.platforms.contains(platform)
                    ) {
                        if draftStore.currentDraft.platforms.contains(platform) {
                            draftStore.currentDraft.platforms.removeAll { $0 == platform }
                        } else {
                            draftStore.currentDraft.platforms.append(platform)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Content Editor
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONTENT")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            TextEditor(text: $draftStore.currentDraft.content)
                .font(.system(size: 15))
                .foregroundColor(Color.appText)
                .frame(minHeight: 150, maxHeight: 250)
                .padding(12)
                .background(Color.appSecondary)
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            // Character limit warnings
            if !draftStore.currentDraft.platforms.isEmpty {
                characterLimitWarnings
            }
        }
    }
    
    // MARK: - Character Limit Warnings
    private var characterLimitWarnings: some View {
        let contentLength = draftStore.currentDraft.content.count + selectedHashtags.joined(separator: " ").count
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(draftStore.currentDraft.platforms.filter { contentLength > $0.characterLimit }) { platform in
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("\(platform.rawValue): \(contentLength - platform.characterLimit) characters over limit")
                        .font(AppTypography.sectionLabel)
                }
                .foregroundStyle(Color.red)
            }
        }
    }
    
    // MARK: - Hashtag Section
    private var hashtagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HASHTAGS")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Button {
                    showHashtagPicker.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showHashtagPicker ? "chevron.up" : "chevron.down")
                        Text(showHashtagPicker ? "Hide" : "Show Suggestions")
                    }
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            
            // Selected hashtags
            if !selectedHashtags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedHashtags, id: \.self) { tag in
                            SelectedHashtagChip(tag: tag) {
                                selectedHashtags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
            
            // Hashtag picker
            if showHashtagPicker {
                hashtagPicker
            }
        }
    }
    
    // MARK: - Hashtag Picker
    private var hashtagPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Suggested based on content
            if !draftStore.currentDraft.content.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested for your content")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(hashtagStore.suggestHashtags(for: draftStore.currentDraft.content)) { hashtag in
                                HashtagButton(hashtag: hashtag, isSelected: selectedHashtags.contains(hashtag.tag)) {
                                    toggleHashtag(hashtag.tag)
                                }
                            }
                        }
                    }
                }
            }
            
            // Categories
            ForEach(HashtagCategory.allCases) { category in
                let categoryHashtags = hashtagStore.hashtags(for: category)
                if !categoryHashtags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.rawValue)
                            .font(AppTypography.sectionLabel)
                            .foregroundStyle(Color.appTextMuted)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(categoryHashtags) { hashtag in
                                    HashtagButton(hashtag: hashtag, isSelected: selectedHashtags.contains(hashtag.tag)) {
                                        toggleHashtag(hashtag.tag)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.appSecondary.opacity(0.5))
        .cornerRadius(AppDimensions.borderRadius)
    }
    
    private func toggleHashtag(_ tag: String) {
        if selectedHashtags.contains(tag) {
            selectedHashtags.removeAll { $0 == tag }
        } else {
            selectedHashtags.append(tag)
            if let hashtag = hashtagStore.hashtags.first(where: { $0.tag == tag }) {
                hashtagStore.incrementUsage(hashtag)
            }
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let platform = draftStore.currentDraft.platforms.first {
                Text("TIPS FOR \(platform.rawValue.uppercased())")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(platform.growthTips.prefix(2), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.yellow)
                            Text(tip)
                                .font(AppTypography.body)
                                .foregroundStyle(Color.appTextMuted)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("Best times:")
                            .font(AppTypography.sectionLabel)
                            .foregroundStyle(Color.appTextMuted)
                        
                        ForEach(platform.bestPostingTimes, id: \.self) { time in
                            Text(time)
                                .font(AppTypography.sectionLabel)
                                .foregroundStyle(Color.appAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appAccent.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(10)
                .background(Color.appSecondary.opacity(0.3))
                .cornerRadius(AppDimensions.borderRadius)
            }
        }
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MEDIA")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Button {
                    openMediaPicker()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Media")
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            
            if draftStore.currentDraft.media.isEmpty {
                // Empty state / drop zone
                mediaDropZone
            } else {
                // Media grid
                mediaGrid
            }
        }
    }
    
    // MARK: - Media Drop Zone
    private var mediaDropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36))
                .foregroundStyle(Color.appTextMuted.opacity(0.5))
            
            Text("Drop images or videos here")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextMuted)
            
            Text("or click Add Media")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.appSecondary.opacity(0.5))
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - Media Grid
    private var mediaGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(draftStore.currentDraft.media) { media in
                    MediaThumbnail(
                        media: media,
                        draftStore: draftStore,
                        onRemove: {
                            draftStore.removeMedia(media)
                        }
                    )
                }
                
                // Add more button
                Button {
                    openMediaPicker()
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.appSecondary)
                    .cornerRadius(AppDimensions.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .frame(height: 110)
    }
    
    // MARK: - Drafts Sidebar
    private var draftsSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DRAFTS")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Button {
                    draftStore.newDraft()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppDimensions.padding)
            .padding(.top, AppDimensions.padding)
            
            if draftStore.drafts.isEmpty {
                VStack {
                    Spacer()
                    Text("No drafts yet")
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appTextMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(draftStore.drafts) { draft in
                            DraftRow(
                                draft: draft,
                                isSelected: draft.id == draftStore.currentDraft.id,
                                onSelect: {
                                    draftStore.loadDraft(draft)
                                },
                                onDelete: {
                                    draftStore.deleteDraft(draft)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppDimensions.padding)
                }
            }
        }
        .background(Color.appSecondary.opacity(0.3))
    }
    
    // MARK: - Actions
    
    private func openMediaPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .movie, .video, .mpeg4Movie, .quickTimeMovie]
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                _ = draftStore.addMedia(from: url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    _ = draftStore.addMedia(from: url)
                }
            }
        }
    }
}

// MARK: - Composer Platform Toggle
struct ComposerPlatformToggle: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 14))
                Text(platform.rawValue)
                    .font(AppTypography.body)
            }
            .foregroundStyle(isSelected ? Color.white : Color.appTextMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.appAccent : Color.appSecondary)
            .cornerRadius(AppDimensions.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                    .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Thumbnail
struct MediaThumbnail: View {
    let media: MediaItem
    let draftStore: DraftStore
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            Group {
                if media.isVideo {
                    ZStack {
                        Color.appSecondary
                        VStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appTextMuted)
                            Text(media.displayName)
                                .font(AppTypography.sectionLabel)
                                .foregroundStyle(Color.appTextMuted)
                                .lineLimit(1)
                        }
                    }
                } else if let image = draftStore.loadImage(for: media) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.appSecondary
                }
            }
            .frame(width: 100, height: 100)
            .cornerRadius(AppDimensions.borderRadius)
            .clipped()
            
            // Remove button
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Draft Row
struct DraftRow: View {
    let draft: DraftPost
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(draft.previewText)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if isHovered {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    Text(draft.formattedDate)
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                    
                    if !draft.media.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                            Text("\(draft.media.count)")
                                .font(AppTypography.sectionLabel)
                        }
                        .foregroundStyle(Color.appTextMuted)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(draft.platforms.prefix(3)) { platform in
                            Image(systemName: platform.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextMuted)
                        }
                    }
                }
            }
            .padding(10)
            .background(isSelected ? Color.appAccent.opacity(0.2) : (isHovered ? Color.appSecondary : Color.clear))
            .cornerRadius(AppDimensions.borderRadius)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Post Flow Sheet
struct PostFlowSheet: View {
    @ObservedObject var draftStore: DraftStore
    @ObservedObject var historyStore: HistoryStore
    var onSwitchToPlatform: (Platform) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var postedPlatforms: Set<Platform> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Post to Platforms")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
            
            Text("Click each platform to open it and paste your content")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)
            
            // Content preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Your post:")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Text(draftStore.currentDraft.content)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appText)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSecondary)
                    .cornerRadius(AppDimensions.borderRadius)
                    .lineLimit(4)
            }
            
            // Media preview
            if !draftStore.currentDraft.media.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Media to upload (\(draftStore.currentDraft.media.count)):")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                    
                    HStack {
                        ForEach(draftStore.currentDraft.media.prefix(4)) { media in
                            Button {
                                draftStore.openMediaInFinder(media)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: media.iconName)
                                    Text(media.displayName)
                                        .lineLimit(1)
                                }
                                .font(AppTypography.sectionLabel)
                                .foregroundStyle(Color.appAccent)
                                .padding(6)
                                .background(Color.appSecondary)
                                .cornerRadius(AppDimensions.borderRadius)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text("Click to reveal in Finder for manual upload")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted.opacity(0.7))
                }
            }
            
            Divider()
                .background(Color.appBorder)
            
            // Platform buttons
            VStack(spacing: 8) {
                ForEach(draftStore.currentDraft.platforms, id: \.self) { platform in
                    PostPlatformButton(
                        platform: platform,
                        isPosted: postedPlatforms.contains(platform)
                    ) {
                        draftStore.copyContentToClipboard()
                        postedPlatforms.insert(platform)
                        
                        // Save to history
                        historyStore.addPost(
                            draftStore.currentDraft.content,
                            platforms: [platform],
                            hashtags: []
                        )
                        
                        dismiss()
                        onSwitchToPlatform(platform)
                    }
                }
            }
            
            Spacer()
            
            // Done button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color.appTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 450, height: 550)
        .background(Color.appBackground)
    }
}

// MARK: - Post Platform Button
struct PostPlatformButton: View {
    let platform: Platform
    let isPosted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: platform.iconName)
                    .font(.system(size: 16))
                
                Text("Open \(platform.rawValue)")
                    .font(AppTypography.bodyMedium)
                
                Spacer()
                
                if isPosted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appSuccess)
                } else {
                    Text("Copy & Open")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                }
            }
            .foregroundStyle(isPosted ? Color.appSuccess : Color.appText)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(isPosted ? Color.appSuccess.opacity(0.1) : Color.appSecondary)
            .cornerRadius(AppDimensions.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                    .stroke(isPosted ? Color.appSuccess : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Hashtag Chip
struct SelectedHashtagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(AppTypography.body)
                .foregroundStyle(Color.appAccent)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.appTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.appAccent.opacity(0.1))
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Hashtag Button
struct HashtagButton: View {
    let hashtag: Hashtag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(hashtag.tag)
                .font(AppTypography.body)
                .foregroundStyle(isSelected ? Color.white : Color.appTextMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.appAccent : Color.appSecondary)
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Prompt Button
struct QuickPromptButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.appAccent.opacity(0.1))
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Suggestion Row
struct AISuggestionRow: View {
    let text: String
    let onUse: () -> Void
    let onAppend: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(Color.appText)
                .lineLimit(4)
            
            HStack(spacing: 8) {
                Button {
                    onUse()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Use this")
                    }
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appAccent.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                Button {
                    onAppend()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Append")
                    }
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appSecondary)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(text.count) chars")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted.opacity(0.5))
            }
        }
        .padding(10)
        .background(isHovered ? Color.appSecondary : Color.clear)
        .cornerRadius(AppDimensions.borderRadius)
        .onHover { isHovered = $0 }
    }
}
