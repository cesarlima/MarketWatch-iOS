import UIKit

extension UIStackView {
    static func vertical(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
}
