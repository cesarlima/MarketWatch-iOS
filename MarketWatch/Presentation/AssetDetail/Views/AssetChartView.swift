import RxCocoa
import RxSwift
import UIKit

/// The 7-day chart area: a spinner while loading, the chart when loaded, or a message with a retry button.
/// Hides itself when the asset has no chart data.
final class AssetChartView: UIView {
    private static let minimumHeight: CGFloat = 120
    private static let chartHeight: CGFloat = 90

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let sparklineView = SparklineView()
    private let captionLabel = UILabel(font: .preferredFont(forTextStyle: .caption1),
                                       textColor: .secondaryLabel)
    private let messageLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                       textColor: .secondaryLabel)
    private let retryButton = UIButton(type: .system)
    private lazy var chartStack = UIStackView.vertical([sparklineView, captionLabel], spacing: 6)
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
            isHidden = false
            spinner.startAnimating()
            chartStack.isHidden = true
            unavailableStack.isHidden = true

        case let .loaded(sparkline, trend):
            isHidden = sparkline.isEmpty
            spinner.stopAnimating()
            sparklineView.setValues(sparkline, trend: trend)
            chartStack.isHidden = false
            unavailableStack.isHidden = true

        case let .unavailable(message):
            isHidden = false
            spinner.stopAnimating()
            messageLabel.text = message
            chartStack.isHidden = true
            unavailableStack.isHidden = false
        }
    }
}

// MARK: - Layout

private extension AssetChartView {
    func setUpLayout() {
        captionLabel.text = L10n.Detail.chart7d
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        retryButton.setTitle(L10n.State.retry, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        unavailableStack.alignment = .center
        chartStack.isHidden = true
        unavailableStack.isHidden = true

        [spinner, chartStack, unavailableStack].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minimumHeight),
            sparklineView.heightAnchor.constraint(equalToConstant: Self.chartHeight),

            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            chartStack.topAnchor.constraint(equalTo: topAnchor),
            chartStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            chartStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            chartStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            unavailableStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            unavailableStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            unavailableStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            unavailableStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            unavailableStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
