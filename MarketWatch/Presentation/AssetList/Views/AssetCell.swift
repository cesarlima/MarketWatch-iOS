import RxCocoa
import RxSwift
import UIKit

final class AssetCell: UITableViewCell {
    static let reuseIdentifier = "AssetCell"
    private static let iconSize: CGFloat = 32

    private let iconView = UIImageView()
    private let nameLabel = UILabel(font: .preferredFont(forTextStyle: .headline))
    private let symbolLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                      textColor: .secondaryLabel)
    private let priceLabel = UILabel(font: .monospacedDigit(size: 17, weight: .semibold, textStyle: .body))
    private let changePill = PillLabel()

    private lazy var identityStack = UIStackView.vertical([nameLabel, symbolLabel], spacing: 2)
    private lazy var quoteStack = UIStackView.vertical([priceLabel, changePill], spacing: 4)
    private lazy var contentStack = UIStackView(arrangedSubviews: [iconView, identityStack, quoteStack])
    private var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
        updateLayoutForContentSize()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func configure(with viewModel: AssetCellViewModel,
                   imageLoader: ImageLoader) {
        nameLabel.text = viewModel.name
        symbolLabel.text = viewModel.symbol
        priceLabel.text = viewModel.priceText
        changePill.text = viewModel.changeText
        changePill.backgroundColor = viewModel.trend.pillColor
        loadIcon(from: viewModel.imageURL, with: imageLoader)
    }

    /// A reused cell cancels the previous download, so a late icon never lands on the wrong row.
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        iconView.image = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let previousCategory = previousTraitCollection?.preferredContentSizeCategory

        guard traitCollection.preferredContentSizeCategory != previousCategory else {
            return
        }
        updateLayoutForContentSize()
    }
}

// MARK: - Layout

private extension AssetCell {
    func setUpLayout() {
        iconView.backgroundColor = .secondarySystemFill
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = Self.iconSize / 2
        iconView.clipsToBounds = true
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])

        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentStack.spacing = 12
        contentView.addSubview(contentStack)
        contentStack.pin(to: contentView.layoutMarginsGuide)
    }

    func updateLayoutForContentSize() {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            stackQuoteBelowName()
        } else {
            placeQuoteBesideName()
        }
    }

    func stackQuoteBelowName() {
        contentStack.axis = .vertical
        contentStack.alignment = .leading
        quoteStack.alignment = .leading
        nameLabel.numberOfLines = 0
    }

    func placeQuoteBesideName() {
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        quoteStack.alignment = .trailing
        nameLabel.numberOfLines = 1
    }
}

// MARK: - Icon

private extension AssetCell {
    func loadIcon(from url: URL?, with imageLoader: ImageLoader) {
        guard let url else {
            return
        }
        imageLoader
            .image(for: url)
            .asDriver(onErrorJustReturn: nil)
            .drive(iconView.rx.image)
            .disposed(by: disposeBag)
    }
}

// MARK: - Trend color

private extension Trend {
    var pillColor: UIColor {
        switch self {
        case .up:
            return .systemGreen

        case .down:
            return .systemRed

        case .neutral:
            return .systemGray
        }
    }
}
