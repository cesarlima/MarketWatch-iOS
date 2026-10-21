import RxCocoa
import RxSwift
import UIKit

final class AssetDetailViewController: UIViewController {
    private static let iconSize: CGFloat = 40

    private let viewModel: AssetDetailViewModel
    private let imageLoader: ImageLoader
    private let disposeBag = DisposeBag()

    private let iconView = UIImageView()
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
    private let scrollView = UIScrollView()

    init(viewModel: AssetDetailViewModel,
         imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setUpLayout()
        bind()
    }
}

// MARK: - Layout

private extension AssetDetailViewController {
    func setUpLayout() {
        iconView.backgroundColor = .secondarySystemFill
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = Self.iconSize / 2
        iconView.clipsToBounds = true
        nameLabel.numberOfLines = 0
        arrowView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)

        titleRow.spacing = 12
        titleRow.alignment = .center
        changeRow.spacing = 4
        changeRow.alignment = .center
        contentStack.alignment = .leading
        contentStack.setCustomSpacing(16, after: titleRow)

        view.addSubview(scrollView)
        scrollView.pin(to: view)
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])
    }

    func render(_ header: AssetDetailHeader) {
        nameLabel.text = header.name
        subtitleLabel.text = header.subtitle
        priceLabel.text = header.priceText
        changeLabel.text = header.changeText
        changeLabel.textColor = header.trend.textColor
        arrowView.image = header.trend.arrow
        arrowView.tintColor = header.trend.textColor
        arrowView.isHidden = header.trend == .neutral
    }
}

// MARK: - Binding

private extension AssetDetailViewController {
    func bind() {
        let output = viewModel.transform(AssetDetailViewModel.Input())

        output.header
            .drive(onNext: { [weak self] header in
                self?.render(header)
                self?.loadIcon(from: header.imageURL)
            })
            .disposed(by: disposeBag)
    }

    func loadIcon(from url: URL?) {
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

// MARK: - Trend appearance

private extension Trend {
    var textColor: UIColor {
        switch self {
        case .up:
            return .systemGreen

        case .down:
            return .systemRed

        case .neutral:
            return .secondaryLabel
        }
    }

    var arrow: UIImage? {
        switch self {
        case .up:
            return UIImage(systemName: "arrowtriangle.up.fill")

        case .down:
            return UIImage(systemName: "arrowtriangle.down.fill")

        case .neutral:
            return nil
        }
    }
}
