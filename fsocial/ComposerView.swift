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
    var onSwitchToPlatform: (Platform) -> Void
    
    @State private var showingMediaPicker = false
    @State private var showingSaveDraftAlert = false
    @State private var showingPostFlow = false
    @State private var currentPostingPlatform: Platform?
    
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
            
            // Character count
            Text("\(draftStore.currentDraft.content.count)")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(draftStore.currentDraft.content.count > 280 ? Color.red : Color.appTextMuted)
            
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
    
    // MARK: - Composer Area
    private var composerArea: some View {
        VStack(spacing: 16) {
            // Platform Selection
            platformSelection
            
            // Content Editor
            contentEditor
            
            // Media Section
            mediaSection
            
            Spacer()
        }
        .padding(AppDimensions.padding)
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
                ForEach(draftStore.currentDraft.platforms) { platform in
                    PostPlatformButton(
                        platform: platform,
                        isPosted: postedPlatforms.contains(platform)
                    ) {
                        draftStore.copyContentToClipboard()
                        postedPlatforms.insert(platform)
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
