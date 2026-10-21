import UIKit

extension UIFont {
    /// Fixed-width digits keep prices from shifting, scaled with the user's text size.
    static func monospacedDigit(size: CGFloat,
                                weight: UIFont.Weight,
                                textStyle: UIFont.TextStyle) -> UIFont {
        let font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)

        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
}
