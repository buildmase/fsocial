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
