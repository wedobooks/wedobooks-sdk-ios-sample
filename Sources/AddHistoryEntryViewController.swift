//
//  AddHistoryEntryViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 22/06/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit
import WeDoBooksSDK

/// Small bottom sheet that adds a material to the user's reading history by ISBN.
/// The created entry is marked completed (see `historyOperations.add`).
final class AddHistoryEntryViewController: UIViewController {
    private let descriptionLabel: UILabel = {
        let result = UILabel()
        result.text = "Add a material to your reading history by ISBN. The entry is created as completed."
        result.font = .systemFont(ofSize: 15, weight: .regular)
        result.textColor = .secondaryLabel
        result.numberOfLines = 0
        return result
    }()

    private let textField: UITextField = {
        let result = UITextField()
        result.placeholder = "ISBN (material id)"
        result.borderStyle = .roundedRect
        result.font = .systemFont(ofSize: 17, weight: .regular)
        result.autocorrectionType = .no
        result.autocapitalizationType = .none
        result.keyboardType = .asciiCapable
        result.returnKeyType = .done
        result.clearButtonMode = .whileEditing
        return result
    }()

    private let createButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Create history entry"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let statusLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .systemRed
        result.numberOfLines = 0
        result.isHidden = true
        return result
    }()

    private var isCreating = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [descriptionLabel, textField, createButton, statusLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            createButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        textField.addTarget(self, action: #selector(createTapped), for: .primaryActionTriggered)
    }

    @objc
    private func createTapped() {
        // Drop the keyboard first: the sheet is a fixed small detent that doesn't
        // resize for the keyboard, so the status label and button below the field
        // would otherwise stay hidden behind it.
        view.endEditing(true)
        let materialId = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !materialId.isEmpty else {
            showStatus("Enter an ISBN.")
            return
        }
        guard !isCreating else { return }

        setCreating(true)
        Task { @MainActor [weak self] in
            let result = await WeDoBooksFacade.shared.historyOperations.add(materialId: materialId)
            guard let self else { return }
            self.setCreating(false)
            switch result {
            case .success:
                self.dismiss(animated: true)
            case .failure(let error):
                print("historyOperations.add failed: \(error)")
                self.showStatus(Self.message(for: error))
            }
        }
    }

    private func setCreating(_ creating: Bool) {
        isCreating = creating
        // Block interactive swipe-to-dismiss during the in-flight add so the sheet
        // can't deallocate and silently drop the create's success/error result.
        isModalInPresentation = creating
        createButton.isEnabled = !creating
        textField.isEnabled = !creating
        if creating { statusLabel.isHidden = true }
    }

    private func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    private static func message(for error: HistoryError) -> String {
        switch error {
        case .materialNotFound:
            return "No material found for that ISBN."
        case .alreadyInHistory:
            return "That material is already in history."
        case .noUserSignedIn:
            return "Sign in to add a history entry."
        case .unsupportedInLibraryMode:
            return "History is unavailable in library mode."
        default:
            return "Couldn't add the history entry."
        }
    }
}
