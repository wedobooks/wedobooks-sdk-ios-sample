//
//  HistoryCardView.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 22/06/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit
import WeDoBooksSDK

final class HistoryCardView: UIView {
    private let titleLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 24, weight: .regular)
        result.textColor = .label
        result.textAlignment = .left
        result.numberOfLines = 1
        return result
    }()

    private let authorLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .left
        result.numberOfLines = 1
        return result
    }()

    private let deleteButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(
            systemName: "trash",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        )
        config.baseForegroundColor = .secondaryLabel
        config.contentInsets = .zero
        let result = UIButton(configuration: config)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.accessibilityLabel = "Remove from history"
        return result
    }()

    private var onDelete: (() -> Void)?

    private lazy var markCompleteButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Mark as complete"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private var onMarkComplete: (() -> Void)?

    private let isbnRow = HistoryCardRow()
    private let progressRow = HistoryCardRow()

    private let progressView: UIProgressView = {
        let result = UIProgressView(progressViewStyle: .default)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.trackTintColor = .secondarySystemBackground
        result.progressTintColor = Theme.primary
        return result
    }()

    private let rowsStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 16
        result.alignment = .fill
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        Theme.applyCardStyle(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, authorLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 4

        addSubview(deleteButton)
        addSubview(headerStack)
        addSubview(rowsStack)

        [isbnRow, progressRow].forEach(rowsStack.addArrangedSubview)
        rowsStack.addArrangedSubview(progressView)
        rowsStack.addArrangedSubview(markCompleteButton)
        rowsStack.setCustomSpacing(8, after: progressRow)
        rowsStack.setCustomSpacing(20, after: progressView)

        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        markCompleteButton.addTarget(self, action: #selector(markCompleteTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            deleteButton.widthAnchor.constraint(equalToConstant: 36),
            deleteButton.heightAnchor.constraint(equalToConstant: 36),

            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),

            rowsStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28),

            markCompleteButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func configure(
        item: HistoryItem,
        isCompleted: Bool,
        onMarkComplete: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        titleLabel.text = item.title
        authorLabel.text = item.author.joined(separator: ", ")
        authorLabel.isHidden = item.author.isEmpty
        isbnRow.configure(label: "ISBN", value: item.materialId)
        let clampedProgress = min(1, max(0, item.progress))
        let percent = Int((clampedProgress * 100).rounded())
        progressRow.configure(label: "Progress", value: "\(percent)%", icon: Self.typeIcon(for: item.type))
        progressView.progress = Float(clampedProgress)
        markCompleteButton.isEnabled = !isCompleted
        markCompleteButton.configuration = .standardConfiguration(for: isCompleted ? "Completed" : "Mark as complete")
        self.onMarkComplete = onMarkComplete
        self.onDelete = onDelete
    }

    private static func typeIcon(for type: MaterialType) -> UIImage? {
        let symbolName = type == .audiobook ? "headphones" : "book"
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: symbolName, withConfiguration: config)
    }

    @objc
    private func markCompleteTapped() {
        onMarkComplete?()
    }

    @objc
    private func deleteTapped() {
        onDelete?()
    }
}

private final class HistoryCardRow: UIView {
    private let iconView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .scaleAspectFit
        result.tintColor = .secondaryLabel
        result.setContentHuggingPriority(.required, for: .horizontal)
        result.setContentCompressionResistancePriority(.required, for: .horizontal)
        return result
    }()

    private let labelView: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 18, weight: .regular)
        result.textColor = .label
        return result
    }()

    private let valueLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 18, weight: .regular)
        result.textColor = .label
        result.textAlignment = .right
        result.numberOfLines = 1
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let horizontalStack = UIStackView(arrangedSubviews: [iconView, labelView, valueLabel])
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .fill
        horizontalStack.spacing = 8

        labelView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelView.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Below required so the stack can collapse the icon to zero when it is
        // hidden (ISBN row) without a constraint conflict.
        let iconWidth = iconView.widthAnchor.constraint(equalToConstant: 22)
        let iconHeight = iconView.heightAnchor.constraint(equalToConstant: 22)
        iconWidth.priority = .defaultHigh
        iconHeight.priority = .defaultHigh

        addSubview(horizontalStack)
        NSLayoutConstraint.activate([
            iconWidth,
            iconHeight,

            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(label: String, value: String, icon: UIImage? = nil) {
        labelView.text = label
        valueLabel.text = value
        iconView.image = icon
        iconView.isHidden = (icon == nil)
    }
}
