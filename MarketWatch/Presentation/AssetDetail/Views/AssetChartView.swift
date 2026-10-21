import RxCocoa
import RxSwift
import UIKit

final class AssetChartView: UIView {
    private static let minimumHeight: CGFloat = 120

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                       textColor: .secondaryLabel)
    private let retryButton = UIButton(type: .system)
    private lazy var unavailableStack = UIStackView.vertical([messageLabel, retryButton], spacing: 4)

    var retryTap: ControlEvent<Void> {
        retryButton.rx.tap
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func render(_ state: ChartState) {
        switch state {
        case .loading:
            spinner.startAnimating()
            unavailableStack.isHidden = true

        case .loaded:
            spinner.stopAnimating()
            unavailableStack.isHidden = true

        case let .unavailable(message):
            spinner.stopAnimating()
            messageLabel.text = message
            unavailableStack.isHidden = false
        }
    }
}

// MARK: - Layout

private extension AssetChartView {
    func setUpLayout() {
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        retryButton.setTitle(L10n.State.retry, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unavailableStack.alignment = .center
        unavailableStack.isHidden = true

        [spinner, unavailableStack].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumHeight),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            unavailableStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            unavailableStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            unavailableStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            unavailableStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            unavailableStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
