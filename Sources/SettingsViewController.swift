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
        var buttons: [ButtonModel] = []
        var toggles: [ToggleModel] = []
        var footnote: String?
    }

    private struct ToggleModel {
        let title: String
        let isOn: Bool
        let onChange: (Bool) -> Void
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

    private let supportIdLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 17, weight: .regular)
        result.textColor = .label
        result.numberOfLines = 0
        return result
    }()

    private var actionsByButton: [UIButton: () -> Void] = [:]
    private var supportIdUserId: String?

    private var isLibraryMode: Bool {
        currentEnv.mode == .library
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupViewHierarchy()
        renderSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSupportId()
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
            ], toggles: [
                ToggleModel(
                    title: "Wi-Fi only downloads",
                    isOn: WeDoBooksFacade.shared.configuration.isWifiDownloadOnly
                ) { isOn in
                    WeDoBooksFacade.shared.configuration.isWifiDownloadOnly = isOn
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
            SectionModel(
                title: "READER & PLAYER",
                toggles: readerAndPlayerToggles(),
                footnote: "Applies the next time a book opens. Resets to the app’s defaults when the app restarts."
            ),
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

        if isLibraryMode {
            let supportIdSection = makeSectionStack(title: "SUPPORT ID")
            supportIdSection.addArrangedSubview(supportIdLabel)
            contentStack.addArrangedSubview(supportIdSection)
        }

        for section in sections {
            contentStack.addArrangedSubview(makeSectionView(section: section))
        }
    }

    private func makeSectionStack(title: String) -> UIStackView {
        let header = UILabel()
        header.text = title
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .secondaryLabel

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.addArrangedSubview(header)
        return stack
    }

    private func makeSectionView(section: SectionModel) -> UIView {
        let stack = makeSectionStack(title: section.title)

        for buttonModel in section.buttons {
            let button = makeButton(model: buttonModel)
            actionsByButton[button] = buttonModel.action
            stack.addArrangedSubview(button)
        }

        for toggleModel in section.toggles {
            stack.addArrangedSubview(makeToggleRow(model: toggleModel))
        }

        if let footnote = section.footnote {
            let label = UILabel()
            label.text = footnote
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            stack.addArrangedSubview(label)
        }

        return stack
    }

    private func makeToggleRow(model: ToggleModel) -> UIView {
        let label = UILabel()
        label.text = model.title
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 0

        let toggle = UISwitch()
        toggle.isOn = model.isOn
        toggle.accessibilityLabel = model.title
        toggle.addAction(UIAction { action in
            guard let toggle = action.sender as? UISwitch else { return }
            model.onChange(toggle.isOn)
        }, for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [label, toggle])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        Theme.applyCardStyle(to: row)
        return row
    }

    /// Each switch assigns a new configuration that changes only its own value and keeps the
    /// tap callbacks set in `MainViewController`.
    private func readerAndPlayerToggles() -> [ToggleModel] {
        let configuration = WeDoBooksFacade.shared.configuration
        return [
            ToggleModel(title: "Player: finish button", isOn: configuration.player.showFinishBookButton) { isOn in
                configuration.player = configuration.player.with(showFinishBookButton: isOn)
            },
            ToggleModel(title: "Player: about book button", isOn: configuration.player.showAboutBookButton) { isOn in
                configuration.player = configuration.player.with(showAboutBookButton: isOn)
            },
            ToggleModel(title: "Player: minimize button", isOn: configuration.player.showMinimizeButton) { isOn in
                configuration.player = configuration.player.with(showMinimizeButton: isOn)
            },
            ToggleModel(title: "Reader: finish button", isOn: configuration.reader.showFinishBookButton) { isOn in
                configuration.reader = configuration.reader.with(showFinishBookButton: isOn)
            },
            ToggleModel(title: "Reader: pull down for reading stats", isOn: configuration.reader.pullDownTop) { isOn in
                configuration.reader = configuration.reader.with(pullDownTop: isOn)
            },
            ToggleModel(title: "Reader: page stack at the top", isOn: configuration.reader.showHeaderAnimation) { isOn in
                configuration.reader = configuration.reader.with(showHeaderAnimation: isOn)
            },
        ]
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

    // MARK: - Support ID

    private func loadSupportId() {
        let userId = WeDoBooksFacade.shared.userOperations.currentUserId
        guard isLibraryMode, userId != supportIdUserId else { return }
        supportIdLabel.text = "Loading…"

        Task.detached { [weak self] in
            let result = await WeDoBooksFacade.shared.userOperations.getSupportId()
            await self?.showSupportId(result, for: userId)
        }
    }

    private func showSupportId(_ result: Result<String, SupportIdError>, for userId: String?) {
        guard WeDoBooksFacade.shared.userOperations.currentUserId == userId else { return }
        switch result {
        case .success(let supportId):
            supportIdUserId = userId
            supportIdLabel.text = supportId
        case .failure(let error):
            print("userOperations.getSupportId failed: \(error)")
            supportIdLabel.text = Self.message(for: error)
        }
    }

    private static func message(for error: SupportIdError) -> String {
        switch error {
        case .noUserSignedIn:
            return "Sign in to see the support ID"
        case .userNotReady:
            return "Not ready yet, reopen Settings to retry"
        default:
            return "Couldn't load the support ID"
        }
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

private extension PlayerConfiguration {
    func with(
        showMinimizeButton: Bool? = nil,
        showFinishBookButton: Bool? = nil,
        showAboutBookButton: Bool? = nil
    ) -> PlayerConfiguration {
        PlayerConfiguration(
            showMinimizeButton: showMinimizeButton ?? self.showMinimizeButton,
            onTappedMinimizeButton: onTappedMinimizeButton,
            showFinishBookButton: showFinishBookButton ?? self.showFinishBookButton,
            onTappedFinishBookButton: onTappedFinishBookButton,
            showAboutBookButton: showAboutBookButton ?? self.showAboutBookButton
        )
    }
}

private extension ReaderConfiguration {
    func with(
        pullDownTop: Bool? = nil,
        showHeaderAnimation: Bool? = nil,
        showFinishBookButton: Bool? = nil
    ) -> ReaderConfiguration {
        ReaderConfiguration(
            pullDownTop: pullDownTop ?? self.pullDownTop,
            showHeaderAnimation: showHeaderAnimation ?? self.showHeaderAnimation,
            showFinishBookButton: showFinishBookButton ?? self.showFinishBookButton,
            onTappedFinishBookButton: onTappedFinishBookButton,
            highlightCallback: highlightCallback,
            loadAllHighlightNotes: loadAllHighlightNotes
        )
    }
}
