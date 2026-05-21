//
//  StatsCardView.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit
import WeDoBooksSDK

final class StatsCardView: UIView {
    private let titleLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 24, weight: .regular)
        result.textColor = .label
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    private let subtitleLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        return result
    }()

    private let rowsStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 24
        result.alignment = .fill
        return result
    }()

    private let audioRow = StatsCardRow()
    private let ebookRow = StatsCardRow()
    private let totalRow = StatsCardRow()
    private let wordsRow = StatsCardRow()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        Theme.applyCardStyle(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.alignment = .fill
        headerStack.spacing = 4

        addSubview(headerStack)
        addSubview(rowsStack)

        [audioRow, ebookRow, totalRow, wordsRow].forEach(rowsStack.addArrangedSubview)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            rowsStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 28),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28),
        ])
    }

    func configure(title: String, subtitle: String, entry: StatEntry) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        audioRow.configure(label: "Audio listened", seconds: entry.audioSeconds)
        ebookRow.configure(label: "Ebook read", seconds: entry.ebookSeconds)
        totalRow.configure(label: "Total time", seconds: entry.secondsRead)
        wordsRow.configure(label: "Words read", wordsCount: entry.wordsRead)
    }
}

private final class StatsCardRow: UIView {
    private let labelView: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 18, weight: .regular)
        result.textColor = .label
        return result
    }()

    private let primaryValueLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 18, weight: .regular)
        result.textColor = .label
        result.textAlignment = .right
        return result
    }()

    private let rawValueLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 13, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .right
        return result
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let valuesStack = UIStackView(arrangedSubviews: [primaryValueLabel, rawValueLabel])
        valuesStack.translatesAutoresizingMaskIntoConstraints = false
        valuesStack.axis = .vertical
        valuesStack.alignment = .trailing
        valuesStack.spacing = 2

        let horizontalStack = UIStackView(arrangedSubviews: [labelView, valuesStack])
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .top
        horizontalStack.distribution = .fill

        labelView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valuesStack.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(horizontalStack)
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(label: String, seconds: Int) {
        labelView.text = label
        primaryValueLabel.text = Self.formatDuration(seconds: seconds)
        rawValueLabel.text = "\(seconds) s"
        rawValueLabel.isHidden = false
    }

    func configure(label: String, wordsCount: Int) {
        labelView.text = label
        primaryValueLabel.text = Self.formatInteger(wordsCount)
        rawValueLabel.text = nil
        rawValueLabel.isHidden = true
    }

    private static func formatDuration(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        var components: [String] = []
        if hours > 0 { components.append("\(hours)h") }
        if minutes > 0 { components.append("\(minutes)m") }
        if remainingSeconds > 0 || components.isEmpty { components.append("\(remainingSeconds)s") }
        return components.joined(separator: " ")
    }

    private static func formatInteger(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
