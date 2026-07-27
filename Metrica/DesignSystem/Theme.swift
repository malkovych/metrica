import SwiftUI

/// Семантичні дизайн-токени. Хардкод hex у в'юхах заборонений (крім визначень тем).
protocol Theme {
    var id: ThemeID { get }
    var bg: Color { get }
    var card: Color { get }
    var text: Color { get }
    var sub: Color { get }
    var line: Color { get }
    var green: Color { get }
    var red: Color { get }
    var amber: Color { get }
    var radiusL: CGFloat { get }
    var radiusM: CGFloat { get }
    var radiusS: CGFloat { get }
    var shadowCard: ShadowStyle { get }
    var fontName: String? { get }

    /// `nil` = без бордера (тема A).
    var cardBorder: Color? { get }
    var segmentTrack: Color { get }
    var barTrack: Color { get }
    var barHeight: CGFloat { get }
    var alertBorderWidth: CGFloat { get }
    var usesTabularNums: Bool { get }
    var showsModeBadge: Bool { get }
    var preferredColorScheme: ColorScheme? { get }
    var heroVariant: HeroVariant { get }
    var kpiVariant: KPIVariant { get }
    var chartVariant: ChartVariant { get }

    /// Семантичні поверхні (hex лише в Theme.swift — §7.6).
    var successSoft: Color { get }
    var warnSoft: Color { get }
    var infoSoft: Color { get }
    var dangerSoft: Color { get }
    var shiftSurface: Color { get }
    var shiftMeta: Color { get }
    var shiftBorder: Color { get }
    var chartMuted: Color { get }
    var heroSolid: Color { get }
    var commerceTiles: [Color] { get }
    var previewSwatch: [Color] { get }
    var connectedBadgeForeground: Color { get }

    func accent(for mode: BusinessMode) -> Color
    func accent2(for mode: BusinessMode) -> Color
    func accentSoft(for mode: BusinessMode) -> Color
    func heroGradient(for mode: BusinessMode) -> LinearGradient
}

enum HeroVariant {
    case gradientSoft   // A
    case darkNeon       // B
    case opsGrid        // C — без героя
    case darkSolid      // D
}

enum KPIVariant {
    case soft       // A 2×2
    case fintech    // B CAPS + tabular
    case ops        // C compact 3×2
    case commerce   // D icon tiles
}

enum ChartVariant {
    case whiteBarsOnHero
    case accentLine
    case greenBarsOnCard
    case greyBarsPeakAccent
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
}

enum ThemeID: String, CaseIterable, Identifiable {
    case aSoft = "theme.a.soft"
    case bDarkFintech = "theme.b.darkFintech"
    case cCleanOps = "theme.c.cleanOps"
    case dCommercePro = "theme.d.commercePro"

    var id: String { rawValue }
    var isAvailable: Bool { true }

    var localizationKey: String {
        switch self {
        case .aSoft: return "theme_a"
        case .bDarkFintech: return "theme_b"
        case .cCleanOps: return "theme_c"
        case .dCommercePro: return "theme_d"
        }
    }

    var subtitleKey: String {
        switch self {
        case .aSoft: return "th_a"
        case .bDarkFintech: return "th_b"
        case .cCleanOps: return "th_c"
        case .dCommercePro: return "th_d"
        }
    }

    var displayName: String {
        switch self {
        case .aSoft: return "iOS Soft"
        case .bDarkFintech: return "Dark Fintech"
        case .cCleanOps: return "Clean Ops"
        case .dCommercePro: return "Commerce Pro"
        }
    }
}

enum ThemeRegistry {
    static func theme(for id: ThemeID) -> any Theme {
        switch id {
        case .aSoft: return ThemeA()
        case .bDarkFintech: return ThemeB()
        case .cCleanOps: return ThemeC()
        case .dCommercePro: return ThemeD()
        }
    }
}

// MARK: - Theme A · iOS Soft

struct ThemeA: Theme {
    let id: ThemeID = .aSoft
    let bg = Color(hex: 0xF4F3F8)
    let card = Color(hex: 0xFFFFFF)
    let text = Color(hex: 0x17171C)
    /// AA на card/bg (≥4.5:1); було #9694A3 ≈ 3.0:1.
    let sub = Color(hex: 0x6E6C7A)
    let line = Color(hex: 0xF0EFF5)
    let green = Color(hex: 0x2FBF71)
    let red = Color(hex: 0xF7444E)
    let amber = Color(hex: 0xE8930C)
    let radiusL: CGFloat = 24
    let radiusM: CGFloat = 18
    let radiusS: CGFloat = 12
    let shadowCard = ShadowStyle(color: Color(hex: 0x17171C).opacity(0.05), radius: 12, x: 0, y: 2)
    let fontName: String? = "Manrope"
    let cardBorder: Color? = nil
    let segmentTrack = Color(hex: 0xE7E6EE)
    var barTrack: Color { bg }
    let barHeight: CGFloat = 9
    let alertBorderWidth: CGFloat = 4
    let usesTabularNums = false
    let showsModeBadge = false
    let preferredColorScheme: ColorScheme? = .light
    let heroVariant: HeroVariant = .gradientSoft
    let kpiVariant: KPIVariant = .soft
    let chartVariant: ChartVariant = .whiteBarsOnHero
    let successSoft = Color(hex: 0xE8F9EE)
    let warnSoft = Color(hex: 0xFFF6E5)
    let infoSoft = Color(hex: 0xEEF3FF)
    let dangerSoft = Color(hex: 0xFDEDED)
    let shiftSurface = Color(hex: 0xEAF9F1)
    let shiftMeta = Color(hex: 0x5E8770)
    let shiftBorder = Color(hex: 0xCBE9DC)
    let chartMuted = Color(hex: 0x3A3E52)
    let heroSolid = Color(hex: 0x1B1D29)
    let commerceTiles: [Color] = [
        Color(hex: 0x6366F1), Color(hex: 0x0E9F6E), Color(hex: 0xFF6B35), Color(hex: 0xE11D48),
    ]
    let previewSwatch: [Color] = [Color(hex: 0xFF6B35), Color(hex: 0xF7444E)]
    let connectedBadgeForeground = Color(hex: 0x1E9E4A)

    func accent(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0xFF6B35) : Color(hex: 0x6366F1)
    }

    func accent2(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0xF7444E) : Color(hex: 0x4F46E5)
    }

    func accentSoft(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0xFFF1EC) : Color(hex: 0xEEEDFB)
    }

    func heroGradient(for mode: BusinessMode) -> LinearGradient {
        LinearGradient(
            colors: [accent(for: mode), accent2(for: mode)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Theme B · Dark Fintech

struct ThemeB: Theme {
    let id: ThemeID = .bDarkFintech
    let bg = Color(hex: 0x0C0D12)
    let card = Color(hex: 0x16181F)
    let text = Color(hex: 0xF2F3F7)
    /// Піднято з #5B5E6E → AA на card (≥4.5:1), §7.4.
    let sub = Color(hex: 0x9BA0B5)
    let line = Color(hex: 0x1D2029)
    let green = Color(hex: 0x3DFFA2)
    let red = Color(hex: 0xFF5C7A)
    let amber = Color(hex: 0xFFB03A)
    let radiusL: CGFloat = 18
    let radiusM: CGFloat = 15
    let radiusS: CGFloat = 10
    let shadowCard = ShadowStyle.none
    let fontName: String? = "Space Grotesk"
    let cardBorder: Color? = Color(hex: 0x23262F)
    let segmentTrack = Color(hex: 0x23262F)
    let barTrack = Color(hex: 0x23262F)
    let barHeight: CGFloat = 7
    let alertBorderWidth: CGFloat = 2
    let usesTabularNums = true
    let showsModeBadge = false
    let preferredColorScheme: ColorScheme? = .dark
    let heroVariant: HeroVariant = .darkNeon
    let kpiVariant: KPIVariant = .fintech
    let chartVariant: ChartVariant = .accentLine
    let successSoft = Color(hex: 0x3DFFA2).opacity(0.12)
    let warnSoft = Color(hex: 0xFFB03A).opacity(0.14)
    let infoSoft = Color(hex: 0x2ED3F7).opacity(0.12)
    let dangerSoft = Color(hex: 0xFF5C7A).opacity(0.14)
    let shiftSurface = Color(hex: 0x16181F)
    let shiftMeta = Color(hex: 0x9BA0B5)
    let shiftBorder = Color(hex: 0x23262F)
    let chartMuted = Color(hex: 0x3A3E52)
    let heroSolid = Color(hex: 0x16181F)
    let commerceTiles: [Color] = [
        Color(hex: 0x2ED3F7), Color(hex: 0x3DFFA2), Color(hex: 0xFFB03A), Color(hex: 0xFF5C7A),
    ]
    let previewSwatch: [Color] = [Color(hex: 0x0C0D12)]
    let connectedBadgeForeground = Color(hex: 0x3DFFA2)

    func accent(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0x3DFFA2) : Color(hex: 0x2ED3F7)
    }

    func accent2(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0x3DFFA2) : Color(hex: 0x2ED3F7)
    }

    func accentSoft(for mode: BusinessMode) -> Color { accent(for: mode).opacity(0.12) }
    func heroGradient(for mode: BusinessMode) -> LinearGradient {
        LinearGradient(colors: [card, card], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Theme C · Clean Ops

struct ThemeC: Theme {
    let id: ThemeID = .cCleanOps
    let bg = Color(hex: 0xF7F9FA)
    let card = Color(hex: 0xFFFFFF)
    let text = Color(hex: 0x1A2B33)
    /// AA на card; було #7C8B93 ≈ 3.5:1.
    let sub = Color(hex: 0x5A6B73)
    let line = Color(hex: 0xF1F4F6)
    let green = Color(hex: 0x0E9F6E)
    let red = Color(hex: 0xE02D3C)
    let amber = Color(hex: 0xD97706)
    let radiusL: CGFloat = 15
    let radiusM: CGFloat = 13
    let radiusS: CGFloat = 9
    let shadowCard = ShadowStyle.none
    let fontName: String? = nil
    let cardBorder: Color? = Color(hex: 0xE8EDF0)
    let segmentTrack = Color(hex: 0xEEF2F4)
    var barTrack: Color { bg }
    let barHeight: CGFloat = 8
    let alertBorderWidth: CGFloat = 4
    let usesTabularNums = false
    let showsModeBadge = true
    let preferredColorScheme: ColorScheme? = .light
    let heroVariant: HeroVariant = .opsGrid
    let kpiVariant: KPIVariant = .ops
    let chartVariant: ChartVariant = .greenBarsOnCard
    let successSoft = Color(hex: 0xE8F9EE)
    let warnSoft = Color(hex: 0xFFF6E5)
    let infoSoft = Color(hex: 0xEEF3FF)
    let dangerSoft = Color(hex: 0xFDEDED)
    let shiftSurface = Color(hex: 0xEAF9F1)
    let shiftMeta = Color(hex: 0x5E8770)
    let shiftBorder = Color(hex: 0xCBE9DC)
    let chartMuted = Color(hex: 0xBFE8DB)
    let heroSolid = Color(hex: 0x1A2B33)
    let commerceTiles: [Color] = [
        Color(hex: 0x0E9F6E), Color(hex: 0x0E9F6E), Color(hex: 0xD97706), Color(hex: 0xE02D3C),
    ]
    let previewSwatch: [Color] = [Color(hex: 0xFFFFFF), Color(hex: 0x0E9F6E)]
    let connectedBadgeForeground = Color(hex: 0x1E9E4A)

    func accent(for mode: BusinessMode) -> Color { Color(hex: 0x0E9F6E) }
    func accent2(for mode: BusinessMode) -> Color { Color(hex: 0x0E9F6E) }
    func accentSoft(for mode: BusinessMode) -> Color { Color(hex: 0xEAF9F1) }
    func heroGradient(for mode: BusinessMode) -> LinearGradient {
        LinearGradient(colors: [card, card], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Theme D · Commerce Pro

struct ThemeD: Theme {
    let id: ThemeID = .dCommercePro
    let bg = Color(hex: 0xF6F7FB)
    let card = Color(hex: 0xFFFFFF)
    let text = Color(hex: 0x1B1D29)
    /// AA на card; було #8A8FA3 ≈ 3.2:1.
    let sub = Color(hex: 0x63687A)
    let line = Color(hex: 0xF1F2F8)
    let green = Color(hex: 0x0E9F6E)
    let red = Color(hex: 0xE02D3C)
    let amber = Color(hex: 0xD97706)
    let radiusL: CGFloat = 20
    let radiusM: CGFloat = 16
    let radiusS: CGFloat = 10
    let shadowCard = ShadowStyle.none
    let fontName: String? = nil
    let cardBorder: Color? = Color(hex: 0xE7E9F2)
    let segmentTrack = Color(hex: 0xEEF0F6)
    var barTrack: Color { bg }
    let barHeight: CGFloat = 8
    let alertBorderWidth: CGFloat = 4
    let usesTabularNums = false
    let showsModeBadge = false
    let preferredColorScheme: ColorScheme? = .light
    let heroVariant: HeroVariant = .darkSolid
    let kpiVariant: KPIVariant = .commerce
    let chartVariant: ChartVariant = .greyBarsPeakAccent
    let successSoft = Color(hex: 0xE8F9EE)
    let warnSoft = Color(hex: 0xFFF6E5)
    let infoSoft = Color(hex: 0xEEF3FF)
    let dangerSoft = Color(hex: 0xFDEDED)
    let shiftSurface = Color(hex: 0xEAF9F1)
    let shiftMeta = Color(hex: 0x5E8770)
    let shiftBorder = Color(hex: 0xCBE9DC)
    let chartMuted = Color(hex: 0x3A3E52)
    let heroSolid = Color(hex: 0x1B1D29)
    let commerceTiles: [Color] = [
        Color(hex: 0x6366F1), Color(hex: 0x0E9F6E), Color(hex: 0xFF6B35), Color(hex: 0xE11D48),
    ]
    let previewSwatch: [Color] = [Color(hex: 0xF6F7FB), Color(hex: 0x1B1D29)]
    let connectedBadgeForeground = Color(hex: 0x1E9E4A)

    func accent(for mode: BusinessMode) -> Color {
        mode == .resto ? Color(hex: 0xFF6B35) : Color(hex: 0x5469FF)
    }

    func accent2(for mode: BusinessMode) -> Color { accent(for: mode) }
    func accentSoft(for mode: BusinessMode) -> Color { accent(for: mode).opacity(0.12) }
    func heroGradient(for mode: BusinessMode) -> LinearGradient {
        LinearGradient(colors: [heroSolid, heroSolid], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Card chrome

extension View {
    func themeCardChrome(_ theme: any Theme) -> some View {
        self
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
            .overlay {
                if let border = theme.cardBorder {
                    RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }
            }
            .shadow(
                color: theme.shadowCard.color,
                radius: theme.shadowCard.radius,
                x: theme.shadowCard.x,
                y: theme.shadowCard.y
            )
    }
}

// MARK: - Environment

private struct BizThemeKey: EnvironmentKey {
    static let defaultValue: any Theme = ThemeA()
}

private struct BusinessModeKey: EnvironmentKey {
    static let defaultValue: BusinessMode = .resto
}

extension EnvironmentValues {
    var bizTheme: any Theme {
        get { self[BizThemeKey.self] }
        set { self[BizThemeKey.self] = newValue }
    }

    var businessMode: BusinessMode {
        get { self[BusinessModeKey.self] }
        set { self[BusinessModeKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
