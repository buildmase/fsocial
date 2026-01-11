//
//  Theme.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let appBackground = Color(hex: "111111")
    static let appSecondary = Color(hex: "1a1a1a")
    static let appText = Color(hex: "e5e5e5")
    static let appTextMuted = Color(hex: "a0a0a0")
    static let appAccent = Color(hex: "6b7a8f")
    static let appBorder = Color(hex: "222222")
    static let appBorderHover = Color(hex: "333333")
    static let appSuccess = Color(hex: "22c55e")
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct AppTypography {
    static let sectionLabel = Font.system(size: 11, weight: .medium)
    static let body = Font.system(size: 13, weight: .regular)
    static let bodyMedium = Font.system(size: 13, weight: .medium)
    static let title = Font.system(size: 16, weight: .semibold)
}

// MARK: - Dimensions
struct AppDimensions {
    static let sidebarWidth: CGFloat = 280
    static let borderRadius: CGFloat = 4
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 12
}
