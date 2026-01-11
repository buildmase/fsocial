//
//  Models.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import Foundation

// MARK: - Platform
enum Platform: String, CaseIterable, Identifiable, Codable {
    case x = "X"
    case instagram = "Instagram"
    case threads = "Threads"
    case tiktok = "TikTok"
    case facebook = "Facebook"
    case linkedin = "LinkedIn"
    case letterboxd = "Letterboxd"
    case goodreads = "Goodreads"
    
    var id: String { rawValue }
    
    var url: URL {
        switch self {
        case .x:
            return URL(string: "https://x.com")!
        case .instagram:
            return URL(string: "https://instagram.com")!
        case .threads:
            return URL(string: "https://threads.net")!
        case .tiktok:
            return URL(string: "https://tiktok.com")!
        case .facebook:
            return URL(string: "https://facebook.com")!
        case .linkedin:
            return URL(string: "https://linkedin.com")!
        case .letterboxd:
            return URL(string: "https://letterboxd.com")!
        case .goodreads:
            return URL(string: "https://goodreads.com")!
        }
    }
    
    var iconName: String {
        switch self {
        case .x:
            return "xmark.circle.fill"
        case .instagram:
            return "camera.circle.fill"
        case .threads:
            return "at.circle.fill"
        case .tiktok:
            return "music.note.tv.fill"
        case .facebook:
            return "person.2.circle.fill"
        case .linkedin:
            return "briefcase.circle.fill"
        case .letterboxd:
            return "film.circle.fill"
        case .goodreads:
            return "book.circle.fill"
        }
    }
    
    var characterLimit: Int {
        switch self {
        case .x:
            return 280
        case .instagram:
            return 2200
        case .threads:
            return 500
        case .tiktok:
            return 2200
        case .facebook:
            return 63206
        case .linkedin:
            return 3000
        case .letterboxd:
            return 10000
        case .goodreads:
            return 10000
        }
    }
    
    var bestPostingTimes: [String] {
        switch self {
        case .x:
            return ["9:00 AM", "12:00 PM", "5:00 PM"]
        case .instagram:
            return ["11:00 AM", "1:00 PM", "7:00 PM"]
        case .threads:
            return ["10:00 AM", "1:00 PM", "6:00 PM"]
        case .tiktok:
            return ["7:00 AM", "12:00 PM", "7:00 PM"]
        case .facebook:
            return ["9:00 AM", "1:00 PM", "4:00 PM"]
        case .linkedin:
            return ["8:00 AM", "12:00 PM", "5:00 PM"]
        case .letterboxd:
            return ["6:00 PM", "8:00 PM", "10:00 PM"]
        case .goodreads:
            return ["10:00 AM", "2:00 PM", "8:00 PM"]
        }
    }
    
    var bestDays: [String] {
        switch self {
        case .x:
            return ["Tuesday", "Wednesday", "Thursday"]
        case .instagram:
            return ["Tuesday", "Wednesday", "Friday"]
        case .threads:
            return ["Monday", "Wednesday", "Friday"]
        case .tiktok:
            return ["Tuesday", "Thursday", "Friday"]
        case .facebook:
            return ["Wednesday", "Thursday", "Friday"]
        case .linkedin:
            return ["Tuesday", "Wednesday", "Thursday"]
        case .letterboxd:
            return ["Friday", "Saturday", "Sunday"]
        case .goodreads:
            return ["Saturday", "Sunday", "Monday"]
        }
    }
    
    var growthTips: [String] {
        switch self {
        case .x:
            return [
                "Reply to trending topics within 30 mins",
                "Use 1-2 hashtags max for best reach",
                "Quote tweet popular posts with your take",
                "Post threads for 3x more engagement"
            ]
        case .instagram:
            return [
                "Post Reels for 2x more reach than photos",
                "Use 5-10 relevant hashtags",
                "Reply to comments within 1 hour",
                "Go live weekly to boost algorithm"
            ]
        case .threads:
            return [
                "Cross-post from Instagram for followers",
                "Join conversations early",
                "Keep posts concise and punchy",
                "Use no hashtags (they don't work yet)"
            ]
        case .tiktok:
            return [
                "Hook viewers in first 3 seconds",
                "Post 1-3 times daily",
                "Use trending sounds",
                "Engage with comments immediately"
            ]
        case .facebook:
            return [
                "Native video gets 10x more reach",
                "Ask questions to boost comments",
                "Post in relevant groups",
                "Go live for priority in feeds"
            ]
        case .linkedin:
            return [
                "Personal stories outperform links",
                "Post early morning for professionals",
                "Use line breaks for readability",
                "Comment on others' posts first"
            ]
        case .letterboxd:
            return [
                "Write detailed reviews for visibility",
                "Follow and engage with film critics",
                "Create curated lists",
                "Review new releases quickly"
            ]
        case .goodreads:
            return [
                "Join reading challenges",
                "Write thoughtful reviews",
                "Participate in book clubs",
                "Update reading progress regularly"
            ]
        }
    }
}

// MARK: - Reply Category
enum ReplyCategory: String, CaseIterable, Identifiable, Codable {
    case welcome = "Welcome"
    case hype = "Hype"
    case thanks = "Thanks"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Quick Reply
struct QuickReply: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var category: ReplyCategory
    var isDefault: Bool
    
    init(id: UUID = UUID(), text: String, category: ReplyCategory, isDefault: Bool = false) {
        self.id = id
        self.text = text
        self.category = category
        self.isDefault = isDefault
    }
}

// MARK: - Default Replies
extension QuickReply {
    static let defaultReplies: [QuickReply] = [
        // Welcome
        QuickReply(text: "Thanks for the follow!", category: .welcome, isDefault: true),
        QuickReply(text: "Welcome! Glad you're here.", category: .welcome, isDefault: true),
        QuickReply(text: "Appreciate the follow!", category: .welcome, isDefault: true),
        
        // Hype
        QuickReply(text: "LET'S GO!", category: .hype, isDefault: true),
        QuickReply(text: "You're crushing it!", category: .hype, isDefault: true),
        QuickReply(text: "Keep that energy!", category: .hype, isDefault: true),
        QuickReply(text: "Built different.", category: .hype, isDefault: true),
        
        // Thanks
        QuickReply(text: "Appreciate you!", category: .thanks, isDefault: true),
        QuickReply(text: "This means everything. Thank you!", category: .thanks, isDefault: true),
        QuickReply(text: "You're the best!", category: .thanks, isDefault: true),
    ]
}

// MARK: - Scheduled Post
struct ScheduledPost: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var platforms: [Platform]
    var scheduledDate: Date
    var isPosted: Bool
    var notes: String
    
    init(id: UUID = UUID(), content: String, platforms: [Platform], scheduledDate: Date, isPosted: Bool = false, notes: String = "") {
        self.id = id
        self.content = content
        self.platforms = platforms
        self.scheduledDate = scheduledDate
        self.isPosted = isPosted
        self.notes = notes
    }
    
    var isPast: Bool {
        scheduledDate < Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(scheduledDate)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
}

// MARK: - Media Item
struct MediaItem: Identifiable, Codable, Equatable {
    let id: UUID
    var fileName: String
    var fileExtension: String
    var isVideo: Bool
    var bookmarkData: Data? // Security-scoped bookmark for file access
    
    init(id: UUID = UUID(), fileName: String, fileExtension: String, isVideo: Bool, bookmarkData: Data? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.isVideo = isVideo
        self.bookmarkData = bookmarkData
    }
    
    var displayName: String {
        "\(fileName).\(fileExtension)"
    }
    
    var iconName: String {
        isVideo ? "video.fill" : "photo.fill"
    }
}

// MARK: - Draft Post
struct DraftPost: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var platforms: [Platform]
    var media: [MediaItem]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), content: String = "", platforms: [Platform] = [], media: [MediaItem] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.platforms = platforms
        self.media = media
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isEmpty: Bool {
        content.isEmpty && media.isEmpty
    }
    
    var previewText: String {
        if content.isEmpty {
            return media.isEmpty ? "Empty draft" : "\(media.count) media item(s)"
        }
        return String(content.prefix(50)) + (content.count > 50 ? "..." : "")
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}

// MARK: - Posted Content (History)
struct PostedContent: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var platforms: [Platform]
    var postedAt: Date
    var mediaCount: Int
    var hashtags: [String]
    
    init(id: UUID = UUID(), content: String, platforms: [Platform], postedAt: Date = Date(), mediaCount: Int = 0, hashtags: [String] = []) {
        self.id = id
        self.content = content
        self.platforms = platforms
        self.postedAt = postedAt
        self.mediaCount = mediaCount
        self.hashtags = hashtags
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: postedAt)
    }
    
    var previewText: String {
        String(content.prefix(100)) + (content.count > 100 ? "..." : "")
    }
}

// MARK: - Hashtag Category
enum HashtagCategory: String, CaseIterable, Identifiable, Codable {
    case growth = "Growth"
    case engagement = "Engagement"
    case trending = "Trending"
    case niche = "Niche"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Hashtag
struct Hashtag: Identifiable, Codable, Equatable {
    let id: UUID
    var tag: String
    var category: HashtagCategory
    var usageCount: Int
    
    init(id: UUID = UUID(), tag: String, category: HashtagCategory, usageCount: Int = 0) {
        self.id = id
        self.tag = tag
        self.category = category
        self.usageCount = usageCount
    }
}

// MARK: - Default Hashtags
extension Hashtag {
    static let defaultHashtags: [Hashtag] = [
        // Growth
        Hashtag(tag: "#followme", category: .growth),
        Hashtag(tag: "#follow4follow", category: .growth),
        Hashtag(tag: "#viral", category: .growth),
        Hashtag(tag: "#explore", category: .growth),
        Hashtag(tag: "#growthhacking", category: .growth),
        
        // Engagement
        Hashtag(tag: "#community", category: .engagement),
        Hashtag(tag: "#letsconnect", category: .engagement),
        Hashtag(tag: "#sharethis", category: .engagement),
        Hashtag(tag: "#comment", category: .engagement),
        Hashtag(tag: "#thoughts", category: .engagement),
        
        // Trending
        Hashtag(tag: "#trending", category: .trending),
        Hashtag(tag: "#fyp", category: .trending),
        Hashtag(tag: "#foryou", category: .trending),
        Hashtag(tag: "#viral2026", category: .trending),
        Hashtag(tag: "#mustwatch", category: .trending),
        
        // Niche
        Hashtag(tag: "#entrepreneur", category: .niche),
        Hashtag(tag: "#creator", category: .niche),
        Hashtag(tag: "#contentcreator", category: .niche),
        Hashtag(tag: "#digitalmarketing", category: .niche),
        Hashtag(tag: "#smallbusiness", category: .niche),
    ]
}

// MARK: - Platform Content (for multi-platform posting)
struct PlatformContent: Identifiable, Codable, Equatable {
    let id: UUID
    var platform: Platform
    var content: String
    var hashtags: [String]
    
    init(id: UUID = UUID(), platform: Platform, content: String = "", hashtags: [String] = []) {
        self.id = id
        self.platform = platform
        self.content = content
        self.hashtags = hashtags
    }
    
    var characterCount: Int {
        content.count + hashtags.joined(separator: " ").count + (hashtags.isEmpty ? 0 : 1)
    }
    
    var isOverLimit: Bool {
        characterCount > platform.characterLimit
    }
    
    var remainingCharacters: Int {
        platform.characterLimit - characterCount
    }
}
