import UIKit

final class AssetDetailHeaderView: UIView {
    private let iconView = CoinIconView(size: 40)
    private let nameLabel = UILabel(font: UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold)))
    private let subtitleLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                        textColor: .secondaryLabel)
    private let priceLabel = UILabel(font: .monospacedDigit(size: 34, weight: .bold, textStyle: .largeTitle))
    private let arrowView = UIImageView()
    private let changeLabel = UILabel(font: .monospacedDigit(size: 15, weight: .semibold, textStyle: .subheadline))

    private lazy var identityStack = UIStackView.vertical([nameLabel, subtitleLabel], spacing: 2)
    private lazy var titleRow = UIStackView(arrangedSubviews: [iconView, identityStack])
    private lazy var changeRow = UIStackView(arrangedSubviews: [arrowView, changeLabel])
    private lazy var contentStack = UIStackView.vertical([titleRow, priceLabel, changeRow], spacing: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func render(_ header: AssetDetailHeader, imageLoader: ImageLoader) {
        iconView.load(header.imageURL, with: imageLoader)
        nameLabel.text = header.name
        subtitleLabel.text = header.subtitle
        priceLabel.text = header.priceText
        changeLabel.text = header.changeText
        changeLabel.textColor = header.trend.color
        arrowView.image = header.trend.arrow
        arrowView.tintColor = header.trend.color
        arrowView.isHidden = header.trend == .neutral
    }
}

// MARK: - Layout

private extension AssetDetailHeaderView {
    func setUpLayout() {
        nameLabel.numberOfLines = 0
        arrowView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)

        titleRow.spacing = 12
        titleRow.alignment = .center
        changeRow.spacing = 4
        changeRow.alignment = .center
        contentStack.alignment = .leading
        contentStack.setCustomSpacing(16, after: titleRow)

        addSubview(contentStack)
        contentStack.pin(to: self)
    }
}
