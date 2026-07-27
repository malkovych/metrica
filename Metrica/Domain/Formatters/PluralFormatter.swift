import Foundation

enum PluralFormatter {
    /// ICU-плюрали через String Catalog (`orders_plural`).
    static func orders(_ count: Int, locale: Locale = .current) -> String {
        String(localized: "orders_plural \(count)", locale: locale)
    }
}
