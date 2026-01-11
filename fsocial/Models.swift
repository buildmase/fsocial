//
//  Models.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import Foundation

// MARK: - Platform
enum Platform: String, CaseIterable, Identifiable {
    case x = "X"
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case linkedin = "LinkedIn"
    
    var id: String { rawValue }
    
    var url: URL {
        switch self {
        case .x:
            return URL(string: "https://x.com")!
        case .instagram:
            return URL(string: "https://instagram.com")!
        case .tiktok:
            return URL(string: "https://tiktok.com")!
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
        case .tiktok:
            return "music.note.tv.fill"
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
