import RxCocoa
import RxSwift
import UIKit

final class AssetDetailViewController: UIViewController {
    private let viewModel: AssetDetailViewModel
    private let imageLoader: ImageLoader
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let headerView = AssetDetailHeaderView()
    private let statsView = AssetStatsView()
    private lazy var contentStack = UIStackView.vertical([headerView, statsView], spacing: 24)

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
        view.addSubview(scrollView)
        scrollView.pin(to: view)
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
}

// MARK: - Binding

private extension AssetDetailViewController {
    func bind() {
        let output = viewModel.transform(AssetDetailViewModel.Input())

        output.header
            .drive(onNext: { [headerView, imageLoader] header in
                headerView.render(header, imageLoader: imageLoader)
            })
            .disposed(by: disposeBag)

        output.stats
            .drive(onNext: { [statsView] stats in
                statsView.render(stats)
            })
            .disposed(by: disposeBag)
    }
}
