//
//  BookEntryView.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

final class BookEntryView: UIView {
    struct ButtonModel {
        let title: String
        let isEnabled: Bool
        let action: () -> Void

        init(title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    struct Section {
        let title: String
        let buttons: [ButtonModel]
    }

    private let mainStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.alignment = .fill
        result.spacing = 16
        return result
    }()

    private let sectionTitleLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 20, weight: .bold)
        result.textColor = .label
        result.numberOfLines = 1
        return result
    }()

    private let isbnLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        result.numberOfLines = 1
        return result
    }()

    private let titleLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 18, weight: .semibold)
        result.textColor = .label
        result.numberOfLines = 0
        return result
    }()

    private let authorLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        result.numberOfLines = 0
        return result
    }()

    private lazy var headerStack: UIStackView = {
        let result = UIStackView(arrangedSubviews: [sectionTitleLabel, isbnLabel, titleLabel, authorLabel])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 4
        result.alignment = .fill
        result.setCustomSpacing(12, after: isbnLabel)
        return result
    }()

    private let sectionsStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 16
        result.alignment = .fill
        return result
    }()

    private var actionButtons: [UIButton] = []
    private var buttonActions: [UIButton: () -> Void] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        Theme.applyCardStyle(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        addSubview(mainStack)

        mainStack.addArrangedSubview(headerStack)
        mainStack.addArrangedSubview(sectionsStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }

    func configureHeader(sectionTitle: String, isbn: String, title: String?, author: String?) {
        sectionTitleLabel.text = sectionTitle
        isbnLabel.text = "ISBN \(isbn)"
        titleLabel.text = title ?? " "
        titleLabel.isHidden = (title?.isEmpty ?? true)
        authorLabel.text = author ?? " "
        authorLabel.isHidden = (author?.isEmpty ?? true)
    }

    func setSections(_ sections: [Section]) {
        sectionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        buttonActions.removeAll()

        for section in sections {
            let container = UIStackView()
            container.axis = .vertical
            container.spacing = 8
            container.alignment = .fill

            let header = UILabel()
            header.text = section.title
            header.font = .systemFont(ofSize: 13, weight: .semibold)
            header.textColor = .secondaryLabel
            container.addArrangedSubview(header)

            for model in section.buttons {
                let button = makeActionButton(title: model.title)
                button.isEnabled = model.isEnabled
                buttonActions[button] = model.action
                button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
                actionButtons.append(button)
                container.addArrangedSubview(button)
            }

            sectionsStack.addArrangedSubview(container)
        }
    }

    func setActionsEnabled(_ isEnabled: Bool) {
        actionButtons.forEach { $0.isEnabled = isEnabled }
    }

    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(configuration: .standardConfiguration(for: title))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    @objc
    private func actionButtonTapped(_ sender: UIButton) {
        buttonActions[sender]?()
    }
}
