import Alamofire
import RxSwift
import UIKit

/// Downloads images and keeps them in memory, so scrolling back doesn't download them again.
final class ImageLoader {
    private static let cacheCountLimit = 200

    private let session: Session
    private let maxPixelSize: Int
    private let cache = NSCache<NSURL, UIImage>()

    /// `maxPixelSize` is the largest side the image is decoded to, e.g. a 32 pt icon on a 3x screen is 96.
    init(session: Session,
         maxPixelSize: Int) {
        self.session = session
        self.maxPixelSize = maxPixelSize
        cache.countLimit = Self.cacheCountLimit
    }

    /// Never fails: a missing image is `nil`, since icons are decorative.
    func image(for url: URL) -> Single<UIImage?> {
        Single.create { [session, cache, maxPixelSize] observer in
            if let cachedImage = cache.object(forKey: url as NSURL) {
                observer(.success(cachedImage))
                return Disposables.create()
            }

            let request = session
                .request(url)
                .validate()
                .responseData { response in
                    let image = response.result.image(maxPixelSize: maxPixelSize)
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
    func image(maxPixelSize: Int) -> UIImage? {
        switch self {
        case let .success(data):
            return UIImage.reduced(from: data, maxPixelSize: maxPixelSize)

        case .failure:
            return nil
        }
    }
}
