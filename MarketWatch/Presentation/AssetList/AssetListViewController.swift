import RxCocoa
import RxSwift
import UIKit

final class AssetListViewController: UIViewController {
    private static let cellIdentifier = "AssetCell"

    private let viewModel: AssetListViewModel
    private let tableView = UITableView()
    private let disposeBag = DisposeBag()

    init(viewModel: AssetListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.List.title
        view.backgroundColor = .systemBackground
        setUpTableView()
        bind()
    }
}

// MARK: - Layout

private extension AssetListViewController {
    func setUpTableView() {
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: Self.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - Binding

private extension AssetListViewController {
    func bind() {
        let output = viewModel.transform(AssetListViewModel.Input())

        output.cells
            .drive(tableView.rx.items(cellIdentifier: Self.cellIdentifier)) { _, cellViewModel, cell in
                var content = cell.defaultContentConfiguration()
                content.text = cellViewModel.name
                content.secondaryText = cellViewModel.priceText
                cell.contentConfiguration = content
            }
            .disposed(by: disposeBag)
    }
}
