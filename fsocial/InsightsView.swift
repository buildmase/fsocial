//
//  InsightsView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI

struct InsightsView: View {
    @ObservedObject var historyStore: HistoryStore
    @ObservedObject var hashtagStore: HashtagStore
    @State private var selectedPlatform: Platform?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header
                
                // Stats Overview
                statsOverview
                
                // Best Times Section
                bestTimesSection
                
                // Platform Breakdown
                platformBreakdown
                
                // Growth Tips
                growthTipsSection
                
                // Top Hashtags
                topHashtagsSection
                
                // Post History
                postHistorySection
            }
            .padding(AppDimensions.padding)
        }
        .background(Color.appBackground)
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Insights & Analytics")
                .font(AppTypography.title)
                .foregroundStyle(Color.appText)
            
            Text("Track your posting activity and optimize your content")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextMuted)
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OVERVIEW")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            HStack(spacing: 16) {
                StatCard(title: "Total Posts", value: "\(historyStore.totalPosts)", icon: "doc.text.fill", color: .appAccent)
                StatCard(title: "This Week", value: "\(historyStore.postsThisWeek)", icon: "calendar", color: .green)
                StatCard(title: "This Month", value: "\(historyStore.postsThisMonth)", icon: "calendar.badge.clock", color: .blue)
                StatCard(title: "Avg/Week", value: String(format: "%.1f", historyStore.averagePostsPerWeek), icon: "chart.line.uptrend.xyaxis", color: .purple)
            }
        }
    }
    
    // MARK: - Best Times Section
    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEST TIMES TO POST")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Platform.allCases) { platform in
                        BestTimeCard(platform: platform)
                    }
                }
            }
        }
    }
    
    // MARK: - Platform Breakdown
    private var platformBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLATFORM BREAKDOWN")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            if historyStore.platformBreakdown.isEmpty {
                Text("No posts yet. Start posting to see breakdown!")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextMuted)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appSecondary)
                    .cornerRadius(AppDimensions.borderRadius)
            } else {
                VStack(spacing: 8) {
                    ForEach(historyStore.platformBreakdown, id: \.0) { platform, count in
                        PlatformStatRow(platform: platform, count: count, total: historyStore.totalPosts)
                    }
                }
            }
        }
    }
    
    // MARK: - Growth Tips Section
    private var growthTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GROWTH TIPS")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                Picker("Platform", selection: $selectedPlatform) {
                    Text("All").tag(nil as Platform?)
                    ForEach(Platform.allCases) { platform in
                        Text(platform.rawValue).tag(platform as Platform?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
            
            let tips = selectedPlatform?.growthTips ?? Platform.allCases.flatMap { $0.growthTips }.shuffled().prefix(6).map { $0 }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    GrowthTipCard(tip: tip)
                }
            }
        }
    }
    
    // MARK: - Top Hashtags Section
    private var topHashtagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP HASHTAGS")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
            
            if hashtagStore.topHashtags.isEmpty {
                Text("Use hashtags in your posts to see stats here")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextMuted)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appSecondary)
                    .cornerRadius(AppDimensions.borderRadius)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(hashtagStore.topHashtags) { hashtag in
                            HashtagChip(hashtag: hashtag)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Post History Section
    private var postHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT POSTS")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                Spacer()
                
                if !historyStore.posts.isEmpty {
                    Button {
                        historyStore.clearHistory()
                    } label: {
                        Text("Clear All")
                            .font(AppTypography.sectionLabel)
                            .foregroundStyle(Color.appTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if historyStore.posts.isEmpty {
                Text("Your post history will appear here")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextMuted)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appSecondary)
                    .cornerRadius(AppDimensions.borderRadius)
            } else {
                VStack(spacing: 8) {
                    ForEach(historyStore.posts.prefix(10)) { post in
                        PostHistoryRow(post: post) {
                            historyStore.deletePost(post)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appText)
            
            Text(title)
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary)
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Best Time Card
struct BestTimeCard: View {
    let platform: Platform
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: platform.iconName)
                    .font(.system(size: 16))
                Text(platform.rawValue)
                    .font(AppTypography.bodyMedium)
            }
            .foregroundStyle(Color.appText)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Best times:")
                    .font(AppTypography.sectionLabel)
                    .foregroundStyle(Color.appTextMuted)
                
                ForEach(platform.bestPostingTimes, id: \.self) { time in
                    Text(time)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appAccent)
                }
            }
            
            Divider()
                .background(Color.appBorder)
            
            Text(platform.bestDays.joined(separator: ", "))
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color.appSecondary)
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Platform Stat Row
struct PlatformStatRow: View {
    let platform: Platform
    let count: Int
    let total: Int
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: platform.iconName)
                .font(.system(size: 16))
                .foregroundStyle(Color.appAccent)
                .frame(width: 24)
            
            Text(platform.rawValue)
                .font(AppTypography.body)
                .foregroundStyle(Color.appText)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.appSecondary)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.appAccent)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(Color.appText)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(10)
        .background(Color.appSecondary.opacity(0.3))
        .cornerRadius(AppDimensions.borderRadius)
    }
}

// MARK: - Growth Tip Card
struct GrowthTipCard: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.yellow)
            
            Text(tip)
                .font(AppTypography.body)
                .foregroundStyle(Color.appText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondary)
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Hashtag Chip
struct HashtagChip: View {
    let hashtag: Hashtag
    
    var body: some View {
        VStack(spacing: 2) {
            Text(hashtag.tag)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(Color.appAccent)
            
            Text("used \(hashtag.usageCount)x")
                .font(AppTypography.sectionLabel)
                .foregroundStyle(Color.appTextMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appSecondary)
        .cornerRadius(AppDimensions.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Post History Row
struct PostHistoryRow: View {
    let post: PostedContent
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.previewText)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appText)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(post.formattedDate)
                        .font(AppTypography.sectionLabel)
                        .foregroundStyle(Color.appTextMuted)
                    
                    HStack(spacing: 4) {
                        ForEach(post.platforms.prefix(4)) { platform in
                            Image(systemName: platform.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextMuted)
                        }
                    }
                    
                    if post.mediaCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "photo")
                                .font(.system(size: 10))
                            Text("\(post.mediaCount)")
                                .font(AppTypography.sectionLabel)
                        }
                        .foregroundStyle(Color.appTextMuted)
                    }
                }
            }
            
            Spacer()
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(isHovered ? Color.appSecondary : Color.appSecondary.opacity(0.5))
        .cornerRadius(AppDimensions.borderRadius)
        .onHover { isHovered = $0 }
    }
}
