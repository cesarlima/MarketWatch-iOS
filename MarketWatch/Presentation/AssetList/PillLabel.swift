import UIKit

/// A small rounded label with inner padding, colored by its `backgroundColor`.
final class PillLabel: UILabel {
    private let insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .monospacedDigit(size: 12, weight: .semibold, textStyle: .caption1)
        adjustsFontForContentSizeCategory = true
        textColor = .white
        layer.cornerRadius = 5
        layer.masksToBounds = true
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize

        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
