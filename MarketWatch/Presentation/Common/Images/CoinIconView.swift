import RxCocoa
import RxSwift
import UIKit

/// A round coin icon that downloads its own image, showing a gray circle until it arrives.
final class CoinIconView: UIImageView {
    private var disposeBag = DisposeBag()

    init(size: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemFill
        contentMode = .scaleAspectFit
        layer.cornerRadius = size / 2
        clipsToBounds = true

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    /// Cancels the previous download first, so a late image never replaces the current one.
    func load(_ url: URL?, with imageLoader: ImageLoader) {
        reset()
        guard let url else {
            return
        }
        imageLoader
            .image(for: url)
            .asDriver(onErrorJustReturn: nil)
            .drive(rx.image)
            .disposed(by: disposeBag)
    }

    func reset() {
        disposeBag = DisposeBag()
        image = nil
    }
}
