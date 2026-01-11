//
//  SidebarView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedPlatform: Platform
    @ObservedObject var replyStore: QuickReplyStore
    @ObservedObject var scheduleStore: ScheduleStore
    @Binding var viewMode: ViewMode
    var onReplySelected: (String) -> Void
    
    @State private var showingAddReply = false
    @State private var newReplyText = ""
    @State private var editingReply: QuickReply?
    @State private var editText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo
            logoSection
            
            Divider()
                .background(Color.appBorder)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // View Mode Toggle
                    viewModeSection
                    
                    Divider()
                        .background(Color.appBorder)
                    
                    // Platforms (only show in browser mode)
                    if viewMode == .browser {
                        platformsSection
                        
                        Divider()
                            .background(Color.appBorder)
                        
                        // Quick Replies
                        quickRepliesSection
                    } else {
                        // Upcoming posts preview in scheduler mode
                        upcomingPostsSection
                    }
                }
                .padding(.vertical, AppDimensions.padding)
            }
            
            Divider()
                .background(Color.appBorder)
            
            // Bottom button
            if viewMode == .browser {
                addReplyButton
            } else {
                schedulerStatsSection
            }
        }
        .frame(width: AppDimensions.sidebarWidth)
        .background(Color.appBackground)
        .sheet(isPresented: $showingAddReply) {
            addReplySheet
        }
        .sheet(item: $editingReply) { reply in
            editReplySheet(reply: reply)
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .cornerRadius(6)
            
            Text("Social Hub")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
        }
        .padding(AppDimensions.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - View Mode Section
    private var viewModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VIEW")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
                .padding(.horizontal, AppDimensions.padding)
            
            HStack(spacing: 8) {
                ViewModeButton(
                    title: "Platforms",
                    icon: "globe",
                    isSelected: viewMode == .browser
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = .browser
                    }
                }
                
                ViewModeButton(
                    title: "Calendar",
                    icon: "calendar",
                    isSelected: viewMode == .scheduler
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = .scheduler
                    }
                }
            }
            .padding(.horizontal, AppDimensions.padding)
        }
    }
    
    // MARK: - Platforms Section
    private var platformsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLATFORMS")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
                .padding(.horizontal, AppDimensions.padding)
            
            ForEach(Platform.allCases) { platform in
                PlatformButton(
                    platform: platform,
                    isSelected: selectedPlatform == platform
                ) {
                    selectedPlatform = platform
                }
            }
        }
    }
    
    // MARK: - Quick Replies Section
    private var quickRepliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK REPLIES")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
                .padding(.horizontal, AppDimensions.padding)
            
            ForEach(ReplyCategory.allCases) { category in
                ReplyCategorySection(
                    category: category,
                    replies: replyStore.replies(for: category),
                    onReplySelected: onReplySelected,
                    onEdit: { reply in
                        editText = reply.text
                        editingReply = reply
                    },
                    onDelete: { reply in
                        replyStore.deleteReply(reply)
                    }
                )
            }
        }
    }
    
    // MARK: - Upcoming Posts Section
    private var upcomingPostsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPCOMING")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
                .padding(.horizontal, AppDimensions.padding)
            
            if scheduleStore.upcomingPosts.isEmpty {
                Text("No upcoming posts")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextMuted)
                    .padding(.horizontal, AppDimensions.padding)
            } else {
                ForEach(scheduleStore.upcomingPosts.prefix(5)) { post in
                    UpcomingPostRow(post: post)
                }
                
                if scheduleStore.upcomingPosts.count > 5 {
                    Text("+\(scheduleStore.upcomingPosts.count - 5) more")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                        .padding(.horizontal, AppDimensions.padding)
                }
            }
            
            // Today's posts
            if !scheduleStore.todaysPosts.isEmpty {
                Divider()
                    .background(Color.appBorder)
                    .padding(.vertical, 8)
                
                Text("TODAY")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, AppDimensions.padding)
                
                ForEach(scheduleStore.todaysPosts) { post in
                    UpcomingPostRow(post: post, isToday: true)
                }
            }
        }
    }
    
    // MARK: - Add Reply Button
    private var addReplyButton: some View {
        Button {
            showingAddReply = true
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add reply")
            }
            .font(AppTypography.bodyMedium)
            .foregroundStyle(Color.appAccent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppDimensions.padding)
        }
        .buttonStyle(.plain)
        .background(Color.appBackground)
    }
    
    // MARK: - Scheduler Stats Section
    private var schedulerStatsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(scheduleStore.upcomingPosts.count)")
                    .font(AppTypography.title)
                    .foregroundStyle(Color.appText)
                Text("Scheduled")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(scheduleStore.todaysPosts.count)")
                    .font(AppTypography.title)
                    .foregroundStyle(Color.appAccent)
                Text("Today")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
            }
        }
        .padding(AppDimensions.padding)
        .background(Color.appBackground)
    }
    
    // MARK: - Add Reply Sheet
    private var addReplySheet: some View {
        VStack(spacing: 16) {
            Text("Add Quick Reply")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
            
            TextEditor(text: $newReplyText)
                .font(AppTypography.body)
                .foregroundColor(Color.appText)
                .frame(height: 80)
                .padding(10)
                .background(Color.appSecondary)
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            HStack {
                Button("Cancel") {
                    newReplyText = ""
                    showingAddReply = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Button("Add") {
                    if !newReplyText.isEmpty {
                        replyStore.addReply(newReplyText)
                        newReplyText = ""
                        showingAddReply = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appAccent)
                .disabled(newReplyText.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
        .background(Color.appBackground)
    }
    
    // MARK: - Edit Reply Sheet
    private func editReplySheet(reply: QuickReply) -> some View {
        VStack(spacing: 16) {
            Text("Edit Reply")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
            
            TextEditor(text: $editText)
                .font(AppTypography.body)
                .foregroundColor(Color.appText)
                .frame(height: 80)
                .padding(10)
                .background(Color.appSecondary)
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            HStack {
                Button("Cancel") {
                    editingReply = nil
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Button("Save") {
                    if !editText.isEmpty {
                        replyStore.updateReply(reply, newText: editText)
                        editingReply = nil
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appAccent)
                .disabled(editText.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350)
        .background(Color.appBackground)
    }
}

// MARK: - View Mode Button
struct ViewModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AppTypography.body)
            }
            .foregroundStyle(isSelected ? Color.white : Color.appTextMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.appAccent : Color.appSecondary)
            .cornerRadius(AppDimensions.borderRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Upcoming Post Row
struct UpcomingPostRow: View {
    let post: ScheduledPost
    var isToday: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(post.formattedDate)
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(isToday ? Color.appAccent : Color.appTextMuted)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(post.platforms.prefix(3)) { platform in
                        Image(systemName: platform.iconName)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appTextMuted)
                    }
                }
            }
            
            Text(post.content)
                .font(AppTypography.body)
                .foregroundStyle(Color.appText)
                .lineLimit(2)
        }
        .padding(.horizontal, AppDimensions.padding)
        .padding(.vertical, 6)
    }
}

// MARK: - Platform Button
struct PlatformButton: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSelected ? Color.appAccent : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.appAccent : Color.appTextMuted, lineWidth: 1)
                    )
                
                Image(systemName: platform.iconName)
                    .foregroundStyle(isSelected ? Color.appAccent : Color.appTextMuted)
                
                Text(platform.rawValue)
                    .font(AppTypography.body)
                    .foregroundStyle(isSelected ? Color.appText : Color.appTextMuted)
                
                Spacer()
            }
            .padding(.horizontal, AppDimensions.padding)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.appAccent.opacity(0.1) :
                    (isHovered ? Color.appSecondary : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Reply Category Section
struct ReplyCategorySection: View {
    let category: ReplyCategory
    let replies: [QuickReply]
    let onReplySelected: (String) -> Void
    let onEdit: (QuickReply) -> Void
    let onDelete: (QuickReply) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Category Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.appTextMuted)
                        .frame(width: 12)
                    
                    Text(category.rawValue)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(Color.appText)
                    
                    Spacer()
                    
                    Text("\(replies.count)")
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                }
                .padding(.horizontal, AppDimensions.padding)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            
            // Replies
            if isExpanded {
                ForEach(replies) { reply in
                    QuickReplyRow(
                        reply: reply,
                        onSelect: { onReplySelected(reply.text) },
                        onEdit: { onEdit(reply) },
                        onDelete: { onDelete(reply) }
                    )
                }
            }
        }
    }
}

// MARK: - Quick Reply Row
struct QuickReplyRow: View {
    let reply: QuickReply
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(Color.appTextMuted)
                
                Text(reply.text)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isHovered && !reply.isDefault {
                    HStack(spacing: 4) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appTextMuted)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppDimensions.padding)
            .padding(.leading, 12)
            .padding(.vertical, 4)
            .background(isHovered ? Color.appSecondary : Color.clear)
            .cornerRadius(AppDimensions.borderRadius)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
