import RxCocoa
import RxSwift
import UIKit

final class StateView: UIView {
    private let spinner = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

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

    func render(_ state: ContentState) {
        switch state {
        case .loading:
            spinner.startAnimating()
            messageLabel.isHidden = true
            retryButton.isHidden = true

        case let .empty(message):
            spinner.stopAnimating()
            messageLabel.text = message
            messageLabel.isHidden = false
            retryButton.isHidden = true

        case let .error(message):
            spinner.stopAnimating()
            messageLabel.text = message
            messageLabel.isHidden = false
            retryButton.isHidden = false

        case .loaded:
            spinner.stopAnimating()
            messageLabel.isHidden = true
            retryButton.isHidden = true
        }
    }
}

// MARK: - Layout

private extension StateView {
    func setUpLayout() {
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        retryButton.setTitle(L10n.State.retry, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        retryButton.isHidden = true

        let stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }
}
