import UIKit

/// A message at the top of the screen that hides itself after a few seconds.
final class ErrorBanner: UIView {
    private static let displayDuration: TimeInterval = 3
    private static let fadeDuration: TimeInterval = 0.25

    private let messageLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                       textColor: .white)
    private var hideWork: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    /// Shows the message; a new message restarts the countdown.
    func show(_ message: String) {
        messageLabel.text = message
        hideWork?.cancel()

        UIView.animate(withDuration: Self.fadeDuration) {
            self.alpha = 1
        }

        let hideWork = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: Self.fadeDuration) {
                self?.alpha = 0
            }
        }
        self.hideWork = hideWork
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration,
                                      execute: hideWork)
    }
}

// MARK: - Layout

private extension ErrorBanner {
    func setUpLayout() {
        backgroundColor = .systemRed
        layer.cornerRadius = 10
        alpha = 0
        isUserInteractionEnabled = false
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        messageLabel.pin(to: layoutMarginsGuide)
    }
}
