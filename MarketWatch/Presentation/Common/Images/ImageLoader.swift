import Alamofire
import RxSwift
import UIKit

/// Downloads images and keeps them in memory, so scrolling back doesn't download them again.
final class ImageLoader {
    private let session: Session
    private let cache = NSCache<NSURL, UIImage>()

    init(session: Session) {
        self.session = session
    }

    /// Never fails: a missing image is `nil`, since icons are decorative.
    func image(for url: URL) -> Single<UIImage?> {
        Single.create { [session, cache] observer in
            if let cachedImage = cache.object(forKey: url as NSURL) {
                observer(.success(cachedImage))
                return Disposables.create()
            }

            let request = session
                .request(url)
                .validate()
                .responseData { response in
                    let image = response.result.image
                    if let image {
                        cache.setObject(image, forKey: url as NSURL)
                    }
                    observer(.success(image))
                }

            return Disposables.create {
                request.cancel()
            }
        }
    }
}

// MARK: - Decoding

private extension Result where Success == Data {
    var image: UIImage? {
        switch self {
        case let .success(data):
            return UIImage(data: data)

        case .failure:
            return nil
        }
    }
}
