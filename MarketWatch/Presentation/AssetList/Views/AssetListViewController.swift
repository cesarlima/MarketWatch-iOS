import RxCocoa
import RxSwift
import UIKit

final class AssetListViewController: UIViewController {
    var onAssetSelected: ((Asset) -> Void)?

    private let viewModel: AssetListViewModel
    private let imageLoader: ImageLoader
    private let tableView = UITableView()
    private let stateView = StateView()
    private let disposeBag = DisposeBag()

    init(viewModel: AssetListViewModel,
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
        title = L10n.List.title
        view.backgroundColor = .systemBackground
        setUpTableView()
        bind()
    }
}

// MARK: - Layout

private extension AssetListViewController {
    func setUpTableView() {
        tableView.register(AssetCell.self,
                           forCellReuseIdentifier: AssetCell.reuseIdentifier)
        tableView.backgroundView = stateView
        view.addSubview(tableView)
        tableView.pin(to: view)
    }
}

// MARK: - Binding

private extension AssetListViewController {
    func bind() {
        let input = AssetListViewModel.Input(selection: tableView.rx.itemSelected.map(\.row))
        let output = viewModel.transform(input)

        output.cells
            .drive(tableView.rx.items(cellIdentifier: AssetCell.reuseIdentifier,
                                      cellType: AssetCell.self)) { [imageLoader] _, cellViewModel, cell in
                cell.configure(with: cellViewModel,
                               imageLoader: imageLoader)
            }
            .disposed(by: disposeBag)

        output.contentState
            .drive(onNext: { [stateView] state in
                stateView.render(state)
            })
            .disposed(by: disposeBag)

        output.selectedAsset
            .emit(onNext: { [weak self] asset in
                self?.onAssetSelected?(asset)
            })
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [tableView] indexPath in
                tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
