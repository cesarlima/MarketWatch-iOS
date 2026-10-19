import RxSwift

protocol APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) -> Single<T>
}
