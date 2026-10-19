import Alamofire
import Foundation
import RxSwift

final class AlamofireAPIClient: APIClient {
    private let baseURL: String
    private let session: Session
    private let decoder = JSONDecoder()

    init(baseURL: String, session: Session) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) -> Single<T> {
        Single.create { [session, decoder, url = url(for: endpoint)] observer in
            let request = session
                .request(url, parameters: endpoint.parameters)
                .validate()
                .responseDecodable(of: T.self, decoder: decoder) { response in
                    switch response.result {
                    case let .success(value):
                        observer(.success(value))

                    case let .failure(error):
                        observer(.failure(AppError(error)))
                    }
                }

            return Disposables.create {
                request.cancel()
            }
        }
    }

    private func url(for endpoint: Endpoint) -> String {
        baseURL + endpoint.path
    }
}

// MARK: - Error mapping

private extension AppError {
    init(_ error: AFError) {
        switch error {
        case .responseValidationFailed(reason: .unacceptableStatusCode(code: 429)):
            self = .rateLimited

        case let .responseValidationFailed(reason: .unacceptableStatusCode(code)):
            self = .server(statusCode: code)

        case .responseSerializationFailed:
            self = .decoding

        case let .sessionTaskFailed(error as URLError) where Self.offlineCodes.contains(error.code):
            self = .offline

        default:
            self = .unknown
        }
    }

    static let offlineCodes: Set<URLError.Code> = [.notConnectedToInternet, .timedOut, .networkConnectionLost]
}
