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
