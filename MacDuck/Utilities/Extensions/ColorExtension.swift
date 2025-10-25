//
//  ColorExtension.swift
//  MacDuck
//
//  Created by Артём on 26.10.2025.
//

import SwiftUI
import AppKit

extension Color {
    static let blackApp = NSColor.adaptiveColor(lightHex: "#090A0C", darkHex: "#090A0C")
    static let grayApp = NSColor.adaptiveColor(lightHex: "#18191B", darkHex: "#18191B")
    static let lightGrayApp = NSColor.adaptiveColor(lightHex: "#2C2C2E", darkHex: "#2C2C2E")
    static let mainTextApp = NSColor.white
    static let secondaryTextApp = NSColor.white.withAlphaComponent(0.8)
    static let blueAccent = NSColor.adaptiveColor(lightHex: "#007AFF", darkHex: "#007AFF")
    static let greenAccent = NSColor.adaptiveColor(lightHex: "#34C759", darkHex: "#34C759")
    static let redAccent = NSColor.adaptiveColor(lightHex: "#FF3B30", darkHex: "#FF3B30")
    static let orangeAccent = NSColor.adaptiveColor(lightHex: "#FF9500", darkHex: "#FF9500")
    static let yellowAccent = NSColor.adaptiveColor(lightHex: "#FFCC00", darkHex: "#FFCC00")
    static let cardBackgroundApp = NSColor.adaptiveColor(lightHex: "#1C1C1E", darkHex: "#1C1C1E")
    static let borderApp = NSColor.adaptiveColor(lightHex: "#2C2C2E", darkHex: "#2C2C2E")
}

extension Color {
    init(nsColor: NSColor) {
        self.init(nsColor)
    }

    static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: .adaptiveColor(lightHex: light, darkHex: dark))
    }

    init(hex: String, alpha: Double = 1) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        let red = (rgbValue & 0xFF0000) >> 16
        let green = (rgbValue & 0xFF00) >> 8
        let blue = rgbValue & 0xFF
        
        self.init(
            .sRGB,
            red: Double(red) / 0xFF,
            green: Double(green) / 0xFF,
            blue: Double(blue) / 0xFF,
            opacity: alpha
        )
    }
}

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (red, green, blue) = (int >> 8, (int >> 4) & 0xF, int & 0xF)
            self.init(red: CGFloat(red * 17) / 255.0, green: CGFloat(green * 17) / 255.0, blue: CGFloat(blue * 17) / 255.0, alpha: alpha)
        case 6: // RGB (24-bit)
            (red, green, blue) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
            self.init(
                red: CGFloat(red) / 255.0,
                green: CGFloat(green) / 255.0,
                blue: CGFloat(blue) / 255.0,
                alpha: alpha
            )
        default:
            self.init(red: 0, green: 0, blue: 0, alpha: alpha)
        }
    }

    static func adaptiveColor(lightHex: String, darkHex: String) -> NSColor {
        let appearance = NSApplication.shared.effectiveAppearance
        let isDark = appearance.name == .darkAqua
        
        return NSColor(hex: isDark ? darkHex : lightHex)
    }
}
