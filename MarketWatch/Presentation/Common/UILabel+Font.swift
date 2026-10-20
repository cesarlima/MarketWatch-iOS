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
