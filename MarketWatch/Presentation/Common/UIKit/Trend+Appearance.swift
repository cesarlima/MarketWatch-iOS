import UIKit

extension Trend {
    var color: UIColor {
        switch self {
        case .up:
            return .systemGreen

        case .down:
            return .systemRed

        case .neutral:
            return .systemGray
        }
    }

    var arrow: UIImage? {
        switch self {
        case .up:
            return UIImage(systemName: "arrowtriangle.up.fill")

        case .down:
            return UIImage(systemName: "arrowtriangle.down.fill")

        case .neutral:
            return nil
        }
    }
}
