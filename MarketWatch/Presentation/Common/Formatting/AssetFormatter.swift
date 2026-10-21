import Foundation

/// Turns asset values into display text.
///
/// - Numbers follow the given locale; the currency is always USD.
/// - Missing values (`nil`) read "—".
/// - Signs come from `Trend`: "+" for up, "-" for down, none for zero.
/// - "US$" and the compact unit stay glued to the number with non-breaking spaces.
///
/// Building the `NumberFormatter`s is expensive, so create one instance and share it
/// instead of creating one per cell.
///
/// Examples below use `pt_BR`.
struct AssetFormatter {
    private static let nonBreakingSpace = "\u{00A0}"

    private let currency: NumberFormatter
    private let smallCurrency: NumberFormatter
    private let wholeCurrency: NumberFormatter
    private let percent: NumberFormatter

    init(locale: Locale) {
        currency = .currency(locale: locale, minimumFractionDigits: 2, maximumFractionDigits: 2)
        smallCurrency = .significantCurrency(locale: locale)
        wholeCurrency = .currency(locale: locale, minimumFractionDigits: 0, maximumFractionDigits: 0)
        percent = .percent(locale: locale)
    }

    /// `81363` → "US$ 81.363,00".
    /// Below 1 keeps up to 4 significant digits: `0.00000165` → "US$ 0,00000165", `0.999255` → "US$ 0,9993".
    /// Compares after rounding, so `0.99996` reads "US$ 1,00" instead of "US$ 1,0".
    func price(_ value: Double) -> String {
        let roundedValue = (value * 10_000).rounded() / 10_000
        let formatter = roundedValue < 1 ? smallCurrency : currency

        return formatter.text(for: value)
    }

    /// `value` is already a percentage, as the API sends it: `1.82` → "+1,82%", `-0.45337` → "-0,45%", `0` → "0,00%".
    func signedPercent(_ value: Double?) -> String {
        guard let value else {
            return L10n.Value.unavailable
        }
        let magnitude = percent.text(for: abs(value) / 100)

        return signed(magnitude, trend: Trend(percentChange: value))
    }

    /// Absolute 24h change, with the same digits rule as `price`: `-347.47512` → "-US$ 347,48",
    /// `120.5` → "+US$ 120,50", `-0.000517` → "-US$ 0,0005172".
    func signedPrice(_ value: Double?) -> String {
        guard let value else {
            return L10n.Value.unavailable
        }
        return signed(price(abs(value)), trend: Trend(change: value))
    }

    /// Market cap and volume: `1_635_294_681_111` → "US$ 1,64 tri", `14_329_628_188` → "US$ 14,33 bi".
    /// Below one million there is no unit and no cents: `532_104` → "US$ 532.104".
    func compactCurrency(_ value: Double?) -> String {
        guard let value else {
            return L10n.Value.unavailable
        }
        guard let unit = CompactUnit.largest(fitting: value) else {
            return wholeCurrency.text(for: value)
        }
        return currency.text(for: value / unit.size) + Self.nonBreakingSpace + unit.suffix
    }

    private func signed(_ magnitude: String, trend: Trend) -> String {
        switch trend {
        case .up:
            return "+" + magnitude

        case .down:
            return "-" + magnitude

        case .neutral:
            return magnitude
        }
    }
}

// MARK: - Compact units

private extension AssetFormatter {
    struct CompactUnit {
        let size: Double
        let suffix: String

        static let all = [
            CompactUnit(size: 1_000_000_000_000, suffix: L10n.Compact.trillion),
            CompactUnit(size: 1_000_000_000, suffix: L10n.Compact.billion),
            CompactUnit(size: 1_000_000, suffix: L10n.Compact.million)
        ]

        /// Compares after rounding to cents, so 999.996.000 reads "1,00 bi" instead of "1.000,00 mi".
        static func largest(fitting value: Double) -> CompactUnit? {
            all.first { unit in
                let amount = value / unit.size

                return (amount * 100).rounded() / 100 >= 1
            }
        }
    }
}

// MARK: - Formatter setup

private extension NumberFormatter {
    static func currency(locale: Locale, minimumFractionDigits: Int, maximumFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.roundingMode = .halfUp
        return formatter
    }

    static func significantCurrency(locale: Locale) -> NumberFormatter {
        let formatter = currency(locale: locale, minimumFractionDigits: 2, maximumFractionDigits: 2)
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 2
        formatter.maximumSignificantDigits = 4
        return formatter
    }

    static func percent(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter
    }

    func text(for value: Double) -> String {
        string(for: value) ?? L10n.Value.unavailable
    }
}
