//
//  SettingsViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit
import WeDoBooksSDK

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsDidRequestLogout()
}

final class SettingsViewController: UIViewController {
    private struct SectionModel {
        let title: String
        let buttons: [ButtonModel]
    }

    private struct ButtonModel {
        let title: String
        let style: Style
        let action: () -> Void

        enum Style {
            case standard
            case destructive
        }
    }

    weak var delegate: SettingsViewControllerDelegate?

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        return result
    }()

    private let contentStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 24
        result.alignment = .fill
        return result
    }()

    private var actionsByButton: [UIButton: () -> Void] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupViewHierarchy()
        renderSections()
    }

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func renderSections() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionsByButton.removeAll()

        let sections: [SectionModel] = [
            SectionModel(title: "STORAGE", buttons: [
                ButtonModel(title: "Downloaded books", style: .standard) { [weak self] in
                    self?.openDownloadedBooks()
                },
                ButtonModel(title: "Clear all downloads", style: .standard) { [weak self] in
                    self?.clearAllDownloads()
                },
            ]),
            SectionModel(title: "DEVICES", buttons: [
                ButtonModel(title: "Manage devices", style: .standard) { [weak self] in
                    self?.openDevices()
                },
            ]),
            SectionModel(title: "PLAYBACK", buttons: [
                ButtonModel(title: "Stop audio playback", style: .standard) { [weak self] in
                    self?.stopAudio()
                },
            ]),
            SectionModel(title: "APPEARANCE", buttons: [
                ButtonModel(title: "Toggle dark mode", style: .standard) { [weak self] in
                    self?.toggleDarkMode()
                },
            ]),
            SectionModel(title: "HISTORY", buttons: [
                ButtonModel(title: "Add history entry", style: .standard) { [weak self] in
                    self?.addHistoryEntry()
                },
            ]),
            SectionModel(title: "ACCOUNT", buttons: [
                ButtonModel(title: "Sign out", style: .destructive) { [weak self] in
                    self?.delegate?.settingsDidRequestLogout()
                },
            ]),
        ]

        for section in sections {
            contentStack.addArrangedSubview(makeSectionView(section: section))
        }
    }

    private func makeSectionView(section: SectionModel) -> UIView {
        let header = UILabel()
        header.text = section.title
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .secondaryLabel

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.addArrangedSubview(header)

        for buttonModel in section.buttons {
            let button = makeButton(model: buttonModel)
            actionsByButton[button] = buttonModel.action
            stack.addArrangedSubview(button)
        }

        return stack
    }

    private func makeButton(model: ButtonModel) -> UIButton {
        var config = UIButton.Configuration.standardConfiguration(for: model.title)
        if case .destructive = model.style {
            config.baseBackgroundColor = Theme.destructiveFill
            config.baseForegroundColor = Theme.destructiveText
        }
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc
    private func buttonTapped(_ sender: UIButton) {
        actionsByButton[sender]?()
    }

    // MARK: - Actions

    private func openDownloadedBooks() {
        navigationController?.pushViewController(DownloadedBooksViewController(), animated: true)
    }

    private func clearAllDownloads() {
        WeDoBooksFacade.shared.storageOperations.removeAll()
        print("storageOperations.removeAll() invoked")
    }

    private func openDevices() {
        navigationController?.pushViewController(DevicesViewController(), animated: true)
    }

    private func addHistoryEntry() {
        let entryVC = AddHistoryEntryViewController()
        if let sheet = entryVC.sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom(identifier: .init("addHistoryEntry")) { _ in 300 }]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(entryVC, animated: true)
    }

    private func stopAudio() {
        WeDoBooksFacade.shared.bookOperations.stopAudioPlayer()
    }

    private func toggleDarkMode() {
        guard let window = view.window else { return }
        let currentStyle = window.overrideUserInterfaceStyle == .unspecified
            ? window.traitCollection.userInterfaceStyle
            : window.overrideUserInterfaceStyle
        window.overrideUserInterfaceStyle = (currentStyle == .dark) ? .light : .dark
    }
}
