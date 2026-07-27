import CoreGraphics
import Foundation

/// WCAG contrast helpers (M10 / теми §7.4).
enum ContrastRatio {
    /// Відношення контрасту двох sRGB hex (0xRRGGBB).
    static func ratio(fg: UInt32, bg: UInt32) -> Double {
        let l1 = relativeLuminance(fg)
        let l2 = relativeLuminance(bg)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func meetsAA(fg: UInt32, bg: UInt32, largeText: Bool = false) -> Bool {
        ratio(fg: fg, bg: bg) >= (largeText ? 3.0 : 4.5)
    }

    /// Дельти на картках — ≥ 3:1.
    static func meetsDeltaAA(fg: UInt32, bg: UInt32) -> Bool {
        ratio(fg: fg, bg: bg) >= 3.0
    }

    private static func relativeLuminance(_ hex: UInt32) -> Double {
        func channel(_ c: Double) -> Double {
            let s = c / 255
            return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        let r = channel(Double((hex >> 16) & 0xFF))
        let g = channel(Double((hex >> 8) & 0xFF))
        let b = channel(Double(hex & 0xFF))
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
