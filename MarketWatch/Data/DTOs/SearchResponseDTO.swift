/// Mirrors `GET /search`. Only the coin ids are needed: prices come from a second `/coins/markets` call.
struct SearchResponseDTO: Decodable {
    let coins: [SearchCoinDTO]
}

struct SearchCoinDTO: Decodable {
    let id: String
}
