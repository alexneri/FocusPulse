import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Solid color from a 6-digit hex string ("RRGGBB", leading "#" optional).
    init(hex: String) {
        let (r, g, b) = Self.rgb(from: hex)
        self.init(red: r, green: g, blue: b)
    }

    /// Dynamic color for light vs dark. On watchOS, uses the dark hex (no appearance callback API).
    init(hexLight: String, hexDark: String) {
        #if os(watchOS)
        self.init(hex: hexDark)
        #elseif canImport(UIKit)
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: hexDark)
                : UIColor(hex: hexLight)
        })
        #else
        self.init(hex: hexLight)
        #endif
    }

    private static func rgb(from hex: String) -> (Double, Double, Double) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        return (r, g, b)
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
#endif
