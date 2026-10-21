import UIKit

/// One statistic: title on the left, value on the right.
final class StatRowView: UIView {
    private let titleLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                     textColor: .secondaryLabel)
    private let valueLabel = UILabel(font: .monospacedDigit(size: 15, weight: .semibold, textStyle: .subheadline))
    private lazy var contentStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])

    init(stat: AssetDetailStat) {
        super.init(frame: .zero)
        titleLabel.text = stat.title
        valueLabel.text = stat.value
        setUpLayout()
        updateLayoutForContentSize()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
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

private extension StatRowView {
    func setUpLayout() {
        titleLabel.numberOfLines = 0
        valueLabel.numberOfLines = 0
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(contentStack)
        contentStack.pin(to: layoutMarginsGuide)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    }

    /// Accessibility text sizes don't fit side by side, so the value moves below the title.
    func updateLayoutForContentSize() {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            stackValueBelowTitle()
        } else {
            placeValueBesideTitle()
        }
    }

    func stackValueBelowTitle() {
        contentStack.axis = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 2
        valueLabel.textAlignment = .natural
    }

    func placeValueBesideTitle() {
        contentStack.axis = .horizontal
        contentStack.alignment = .firstBaseline
        contentStack.spacing = 12
        valueLabel.textAlignment = .right
    }
}
