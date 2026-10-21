import UIKit

/// A line chart of prices with no axes, drawn with a `CAShapeLayer`.
final class SparklineView: UIView {
    private static let lineWidth: CGFloat = 2

    private let lineLayer = CAShapeLayer()
    private var values: [Double] = []
    private var trend: Trend = .neutral

    override init(frame: CGRect) {
        super.init(frame: frame)
        lineLayer.fillColor = nil
        lineLayer.lineWidth = Self.lineWidth
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        layer.addSublayer(lineLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func setValues(_ values: [Double], trend: Trend) {
        self.values = values
        self.trend = trend
        applyColor()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let drawingArea = bounds.insetBy(dx: Self.lineWidth / 2, dy: Self.lineWidth / 2)
        let points = Self.points(for: values, in: drawingArea)

        let path = UIBezierPath()
        for (index, point) in points.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        lineLayer.frame = bounds
        lineLayer.path = path.cgPath
    }

    /// Layer colors are `CGColor`s, which don't follow Dark Mode by themselves.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColor()
    }

    /// Spreads the values across the width; the lowest goes to the bottom, the highest to the top.
    /// Values that are not finite are ignored. Flat values, or a spread too large to compute, draw a line
    /// in the middle; fewer than 2 values draw nothing.
    static func points(for values: [Double], in rect: CGRect) -> [CGPoint] {
        let values = values.filter(\.isFinite)

        guard values.count >= 2, let lowest = values.min(), let highest = values.max() else {
            return []
        }
        let range = highest - lowest
        let stepX = rect.width / CGFloat(values.count - 1)

        return values.enumerated().map { index, value in
            let height = range > 0 && range.isFinite ? CGFloat((value - lowest) / range) : 0.5

            return CGPoint(x: rect.minX + CGFloat(index) * stepX,
                           y: rect.maxY - height * rect.height)
        }
    }
}

// MARK: - Color

private extension SparklineView {
    func applyColor() {
        lineLayer.strokeColor = trend.color.resolvedColor(with: traitCollection).cgColor
    }
}
