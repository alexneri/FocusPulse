import SwiftUI
import UIKit

extension Color {
    /// Solid color from a 6-digit hex string ("RRGGBB", leading "#" optional).
    init(hex: String) {
        self = Color(UIColor(hex: hex))
    }

    /// A dynamic color that resolves to a different hex for light vs dark appearance.
    init(hexLight: String, hexDark: String) {
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: hexDark) : UIColor(hex: hexLight)
        })
    }
}

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
