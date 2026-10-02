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
        let requiresIsbn: Bool
        let action: () -> Void

        init(title: String, isEnabled: Bool = true, requiresIsbn: Bool = true, action: @escaping () -> Void) {
            self.title = title
            self.isEnabled = isEnabled
            self.requiresIsbn = requiresIsbn
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

    private let isbnField: UITextField = {
        let result = UITextField()
        result.attributedPlaceholder = NSAttributedString(
            string: "ISBN",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        result.borderStyle = .roundedRect
        result.font = .systemFont(ofSize: 17, weight: .regular)
        result.autocorrectionType = .no
        result.autocapitalizationType = .none
        result.keyboardType = .asciiCapable
        result.returnKeyType = .done
        result.clearButtonMode = .whileEditing
        result.translatesAutoresizingMaskIntoConstraints = false
        result.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return result
    }()

    // Pull-down of saved ISBNs, shown inside the field while there are any.
    private let savedIsbnsButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "clock.arrow.circlepath")
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        let result = UIButton(configuration: configuration)
        result.showsMenuAsPrimaryAction = true
        result.accessibilityLabel = "Saved ISBNs"
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
        let result = UIStackView(arrangedSubviews: [sectionTitleLabel, isbnField, titleLabel, authorLabel])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 4
        result.alignment = .fill
        result.setCustomSpacing(12, after: isbnField)
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
    private var buttonModels: [UIButton: ButtonModel] = [:]

    var onIsbnChange: (() -> Void)?

    var isbn: String {
        (isbnField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        isbnField.delegate = self
        isbnField.addTarget(self, action: #selector(isbnFieldChanged), for: .editingChanged)
        isbnField.rightView = savedIsbnsButton
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

    func configureHeader(sectionTitle: String, title: String?, author: String?) {
        sectionTitleLabel.text = sectionTitle
        titleLabel.text = title ?? " "
        titleLabel.isHidden = (title?.isEmpty ?? true)
        authorLabel.text = author ?? " "
        authorLabel.isHidden = (author?.isEmpty ?? true)
    }

    func setSavedIsbns(_ isbns: [String], onRemove: @escaping (String) -> Void) {
        isbnField.rightViewMode = isbns.isEmpty ? .never : .always
        guard !isbns.isEmpty else {
            savedIsbnsButton.menu = nil
            return
        }

        let picks = isbns.map { isbn in
            UIAction(title: isbn, state: isbn == self.isbn ? .on : .off) { [weak self] _ in
                self?.isbnField.text = isbn
                self?.onIsbnChange?()
            }
        }
        let removals = isbns.map { isbn in
            UIAction(title: isbn, attributes: .destructive) { _ in
                onRemove(isbn)
            }
        }
        savedIsbnsButton.menu = UIMenu(children: [
            UIMenu(options: .displayInline, children: picks),
            UIMenu(title: "Remove", image: UIImage(systemName: "trash"), children: removals),
        ])
    }

    func setSections(_ sections: [Section]) {
        sectionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        buttonModels.removeAll()

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
                button.isEnabled = canEnable(model)
                buttonModels[button] = model
                button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
                actionButtons.append(button)
                container.addArrangedSubview(button)
            }

            sectionsStack.addArrangedSubview(container)
        }
    }

    func setActionsEnabled(_ isEnabled: Bool) {
        for button in actionButtons {
            button.isEnabled = isEnabled && buttonModels[button].map(canEnable) ?? false
        }
    }

    private func canEnable(_ model: ButtonModel) -> Bool {
        model.isEnabled && (!model.requiresIsbn || !isbn.isEmpty)
    }

    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(configuration: .standardConfiguration(for: title))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    @objc
    private func isbnFieldChanged() {
        onIsbnChange?()
    }

    @objc
    private func actionButtonTapped(_ sender: UIButton) {
        guard let model = buttonModels[sender], canEnable(model) else { return }
        model.action()
    }
}

extension BookEntryView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async { [weak self] in
            self?.onIsbnChange?()
        }
        return true
    }
}
