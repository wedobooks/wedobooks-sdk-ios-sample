//
//  SegmentedTabBar.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

final class SegmentedTabBar: UIView {
    private let stackView: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .horizontal
        result.alignment = .fill
        result.distribution = .fillEqually
        return result
    }()

    private let separator: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.backgroundColor = .separator
        return result
    }()

    private let indicator: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.backgroundColor = Theme.primary
        return result
    }()

    private var titleButtons: [UIButton] = []
    private var indicatorLeading: NSLayoutConstraint?
    private var indicatorWidth: NSLayoutConstraint?

    private(set) var selectedIndex: Int = 0

    var onSelectionChange: ((Int) -> Void)?

    init(titles: [String]) {
        super.init(frame: .zero)
        setup(titles: titles)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(titles: [String]) {
        addSubview(stackView)
        addSubview(separator)
        addSubview(indicator)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            indicator.heightAnchor.constraint(equalToConstant: 2),
            indicator.bottomAnchor.constraint(equalTo: separator.topAnchor),
        ])

        for (index, title) in titles.enumerated() {
            let button = makeTitleButton(title: title, tag: index)
            stackView.addArrangedSubview(button)
            titleButtons.append(button)
        }

        guard let firstButton = titleButtons.first else { return }
        let leading = indicator.leadingAnchor.constraint(equalTo: firstButton.leadingAnchor)
        let width = indicator.widthAnchor.constraint(equalTo: firstButton.widthAnchor)
        indicatorLeading = leading
        indicatorWidth = width
        NSLayoutConstraint.activate([leading, width])

        applySelectionStyling()
    }

    private func makeTitleButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(Theme.primary, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc
    private func buttonTapped(_ sender: UIButton) {
        setSelectedIndex(sender.tag, animated: true)
        onSelectionChange?(sender.tag)
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard titleButtons.indices.contains(index), index != selectedIndex || indicatorLeading?.firstAnchor !== titleButtons[index].leadingAnchor else {
            selectedIndex = index
            applySelectionStyling()
            return
        }

        selectedIndex = index
        let target = titleButtons[index]

        indicatorLeading?.isActive = false
        indicatorWidth?.isActive = false
        let leading = indicator.leadingAnchor.constraint(equalTo: target.leadingAnchor)
        let width = indicator.widthAnchor.constraint(equalTo: target.widthAnchor)
        indicatorLeading = leading
        indicatorWidth = width
        NSLayoutConstraint.activate([leading, width])

        applySelectionStyling()

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    private func applySelectionStyling() {
        for (index, button) in titleButtons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? Theme.primary : .secondaryLabel, for: .normal)
        }
    }
}
