import RxCocoa
import RxSwift
import UIKit

final class AssetSearchViewController: UIViewController {
    private let viewModel: AssetSearchViewModel
    private let imageLoader: ImageLoader
    private let tableView = UITableView()
    private let disposeBag = DisposeBag()

    init(viewModel: AssetSearchViewModel,
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
        setUpTableView()
    }

    func bind(to searchController: UISearchController) {
        loadViewIfNeeded()
        let input = AssetSearchViewModel.Input(query: searchController.searchBar.rx.text.orEmpty.asObservable())
        let output = viewModel.transform(input)

        bindCells(output.cells)
        bindIsSearchActive(output.isSearchActive, to: searchController)
    }
}

// MARK: - Layout

private extension AssetSearchViewController {
    func setUpTableView() {
        tableView.register(AssetCell.self,
                           forCellReuseIdentifier: AssetCell.reuseIdentifier)
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.pin(to: view)
    }
}

// MARK: - Binding

private extension AssetSearchViewController {
    func bindCells(_ cells: Driver<[AssetCellViewModel]>) {
        cells
            .drive(tableView.rx.items(cellIdentifier: AssetCell.reuseIdentifier,
                                      cellType: AssetCell.self)) { [imageLoader] _, cellViewModel, cell in
                cell.configure(with: cellViewModel,
                               imageLoader: imageLoader)
            }
            .disposed(by: disposeBag)
    }

    func bindIsSearchActive(_ isSearchActive: Driver<Bool>,
                            to searchController: UISearchController) {
        isSearchActive
            .drive(onNext: { [weak searchController] isActive in
                searchController?.showsSearchResultsController = isActive
            })
            .disposed(by: disposeBag)
    }
}
