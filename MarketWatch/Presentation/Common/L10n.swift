import Foundation

enum L10n {
    enum Value {
        static let unavailable = text("value.unavailable")
    }
}

// MARK: - Lookup

private extension L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
    }
}
