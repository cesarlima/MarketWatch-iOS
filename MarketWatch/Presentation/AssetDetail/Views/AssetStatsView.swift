import UIKit

/// The statistics block: one row per stat, on a rounded background, with thin lines between rows.
final class AssetStatsView: UIView {
    private let rowsStack = UIStackView.vertical([], spacing: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func render(_ stats: [AssetDetailStat]) {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, stat) in stats.enumerated() {
            if index > 0 {
                rowsStack.addArrangedSubview(Self.makeSeparator())
            }
            rowsStack.addArrangedSubview(StatRowView(stat: stat))
        }
    }
}

// MARK: - Layout

private extension AssetStatsView {
    func setUpLayout() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        clipsToBounds = true

        addSubview(rowsStack)
        rowsStack.pin(to: self)
    }

    /// A hairline that starts after the row's leading margin, like table view separators.
    static func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator

        let container = UIView()
        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        return container
    }
}
