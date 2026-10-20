import XCTest
@testable import MarketWatch

final class AppErrorMessageTests: XCTestCase {

    func test_errorMessages() {
        XCTAssertEqual(AppError.offline.message, "Sem conexão com a internet.")
        XCTAssertEqual(AppError.rateLimited.message, "Muitas requisições em pouco tempo. Tente novamente em instantes.")
        XCTAssertEqual(AppError.server(statusCode: 503).message, "O serviço de cotações está indisponível no momento.")
        XCTAssertEqual(AppError.decoding.message, "Não foi possível ler os dados recebidos.")
        XCTAssertEqual(AppError.unknown.message, "Algo deu errado. Tente novamente.")
    }
}
