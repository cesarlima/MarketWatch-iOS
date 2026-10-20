import UIKit

extension UILabel {
    convenience init(font: UIFont,
                     textColor: UIColor = .label) {
        self.init(frame: .zero)
        self.font = font
        self.textColor = textColor
        adjustsFontForContentSizeCategory = true
    }
}

extension UIStackView {
    static func vertical(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
}

// MARK: - Pinning

protocol LayoutAnchors {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
}

extension UIView: LayoutAnchors {}
extension UILayoutGuide: LayoutAnchors {}

extension UIView {
    /// Pins all four edges to a view or a layout guide, such as a superview's margins.
    func pin(to anchors: LayoutAnchors) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: anchors.topAnchor),
            bottomAnchor.constraint(equalTo: anchors.bottomAnchor),
            leadingAnchor.constraint(equalTo: anchors.leadingAnchor),
            trailingAnchor.constraint(equalTo: anchors.trailingAnchor)
        ])
    }
}
