import Foundation

enum MoneyFormatter {
    /// Суми з API — у мінорних одиницях (копійки).
    static func string(minorUnits: Int, currencyCode: String, locale: Locale = .current) -> String {
        let major = Decimal(minorUnits) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: major as NSDecimalNumber) ?? "\(major)"
    }

    static func deltaPct(_ value: Double, locale: Locale = .current) -> String {
        let sign = value > 0 ? "▲" : (value < 0 ? "▼" : "–")
        let abs = abs(value)
        let n = abs.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return "\(sign) \(n)%"
    }
}
