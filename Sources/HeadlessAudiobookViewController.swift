//
//  HeadlessAudiobookViewController.swift
//  DevApp
//
//  Created by Bo Gosmer on 24/02/2026.
//

import Combine
import UIKit
import WeDoBooksSDK

final class HeadlessAudiobookViewController: UIViewController, UITextFieldDelegate {
    private enum Constants {
        static let demoAudiobookISBN = currentEnv.audioBookIsbn
        static let controlHeight: CGFloat = 44
        static let keyboardScrollPadding: CGFloat = 28
    }

    private var cancellables: Set<AnyCancellable> = []
    private var audiobookCheckout: Checkout?

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        result.keyboardDismissMode = .interactive
        return result
    }()

    private let contentView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let contentStackView: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 12
        result.alignment = .fill
        return result
    }()

    private let startPositionField = HeadlessAudiobookViewController.makeNumberField(
        placeholder: "Start position in seconds",
        defaultValue: "0"
    )

    private let seekPositionField = HeadlessAudiobookViewController.makeNumberField(
        placeholder: "Seek target in seconds",
        defaultValue: "30"
    )

    private let playbackRateField = HeadlessAudiobookViewController.makeNumberField(
        placeholder: "Playback rate",
        defaultValue: "1.0"
    )

    private let loadBookButton = UIButton(title: "Load book")
    private let playButton = UIButton(title: "Play")
    private let pauseButton = UIButton(title: "Pause")
    private let seekButton = UIButton(title: "Seek")
    private let setRateButton = UIButton(title: "Set rate")
    private let refreshMetricsButton = UIButton(title: "Refresh position/duration")

    private let downloadButton = UIButton(title: "Download")
    private let removeDownloadButton = UIButton(title: "Remove download")
    private let downloadStatusButton = UIButton(title: "Get download status")

    private let checkoutLabel = HeadlessAudiobookViewController.makeStatusLabel("Checkout: not loaded")
    private let stateLabel = HeadlessAudiobookViewController.makeStatusLabel("State: not loaded")
    private let positionLabel = HeadlessAudiobookViewController.makeStatusLabel("Position: n/a")
    private let durationLabel = HeadlessAudiobookViewController.makeStatusLabel("Duration: n/a")
    private let downloadStatusLabel = HeadlessAudiobookViewController.makeStatusLabel("Download statuses: n/a")

    private lazy var numberInputAccessoryToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneEditingTapped)),
        ]
        return toolbar
    }()

    private lazy var backgroundDismissTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    private let eventLogView: UITextView = {
        let result = UITextView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        result.backgroundColor = .secondarySystemBackground
        result.textColor = .label
        result.isEditable = false
        result.isScrollEnabled = true
        result.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        result.text = ""
        return result
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Headless"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label

        setupViewHierarchy()
        setupKeyboardHandling()
        setupControlActions()
        setupBindings()
        
        do {
            let rate = try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .currentRate()
            let roundedValue = round(rate * 10) / 10.0
            playbackRateField.text = "\(roundedValue)"
        } catch {
            print("Error when setting current rate: \(error)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hydrateLoadedSessionState()
    }

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])

        let transportButtonsRow = makeButtonRow(buttons: [playButton, pauseButton])
        let offlineButtonsRow = makeButtonRow(buttons: [downloadButton, removeDownloadButton])

        [
            HeadlessAudiobookViewController.makeSectionLabel("Load"),
            startPositionField,
            loadBookButton,
            checkoutLabel,
            stateLabel,

            HeadlessAudiobookViewController.makeSectionLabel("Transport"),
            transportButtonsRow,
            seekPositionField,
            seekButton,
            playbackRateField,
            setRateButton,
            refreshMetricsButton,
            positionLabel,
            durationLabel,

            HeadlessAudiobookViewController.makeSectionLabel("Offline"),
            offlineButtonsRow,
            downloadStatusButton,
            downloadStatusLabel,

            HeadlessAudiobookViewController.makeSectionLabel("Events"),
            eventLogView,
        ].forEach(contentStackView.addArrangedSubview)

        [
            startPositionField,
            seekPositionField,
            playbackRateField,
        ].forEach {
            $0.heightAnchor.constraint(equalToConstant: Constants.controlHeight).isActive = true
        }

        scrollView.contentInset.bottom = 20
        scrollView.verticalScrollIndicatorInsets.bottom = 20
        
        [
            loadBookButton,
            seekButton,
            setRateButton,
            refreshMetricsButton,
            downloadStatusButton,
        ].forEach {
            $0.heightAnchor.constraint(equalToConstant: Constants.controlHeight).isActive = true
        }

        eventLogView.heightAnchor.constraint(equalToConstant: 220).isActive = true
    }

    private func setupKeyboardHandling() {
        view.addGestureRecognizer(backgroundDismissTapGesture)

        [
            startPositionField,
            seekPositionField,
            playbackRateField,
        ].forEach {
            $0.inputAccessoryView = numberInputAccessoryToolbar
            $0.delegate = self
        }
    }

    private func hydrateLoadedSessionState() {
        if let loadedCheckout = WeDoBooksFacade.shared.headlessAudioPlayer.loadedBook() {
            audiobookCheckout = loadedCheckout
            checkoutLabel.text = "Checkout: \(loadedCheckout.title) (\(loadedCheckout.materialId))"
            setLoadControlsEnabled(false)
            if stateLabel.text == "State: not loaded" {
                stateLabel.text = "State: loaded (awaiting runtime update)"
            }
            refreshMetrics(logResult: false, logErrors: false)
            return
        }

        audiobookCheckout = nil
        checkoutLabel.text = "Checkout: not loaded"
        stateLabel.text = "State: not loaded"
        positionLabel.text = "Position: n/a"
        durationLabel.text = "Duration: n/a"
        downloadStatusLabel.text = "Download statuses: n/a"
        setLoadControlsEnabled(true)
    }

    private func setupControlActions() {
        loadBookButton.addTarget(self, action: #selector(loadBookTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        seekButton.addTarget(self, action: #selector(seekTapped), for: .touchUpInside)
        setRateButton.addTarget(self, action: #selector(setRateTapped), for: .touchUpInside)
        refreshMetricsButton.addTarget(self, action: #selector(refreshMetricsTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        removeDownloadButton.addTarget(self, action: #selector(removeDownloadTapped), for: .touchUpInside)
        downloadStatusButton.addTarget(self, action: #selector(downloadStatusTapped), for: .touchUpInside)
    }

    @objc
    private func backgroundTapped() {
        view.endEditing(true)
    }

    @objc
    private func doneEditingTapped() {
        view.endEditing(true)
    }

    private func setupBindings() {
        WeDoBooksFacade.shared
            .headlessAudioPlayer
            .onStateChange
            .sink { [weak self] state in
                self?.stateLabel.text = "State: \(state)"
                self?.appendLog("state changed: \(state)")
            }
            .store(in: &cancellables)

        WeDoBooksFacade.shared
            .headlessAudioPlayer
            .onError
            .sink { [weak self] error in
                self?.appendLog("headless onError emitted: \(error)")
            }
            .store(in: &cancellables)

        WeDoBooksFacade.shared
            .storageOperations
            .onError
            .sink { [weak self] error in
                self?.appendLog("storage onError emitted: \(error)")
            }
            .store(in: &cancellables)

        WeDoBooksFacade.shared
            .storageOperations
            .downloadStatuses
            .sink { [weak self] statuses in
                let formattedStatuses = self?.formattedDownloadStatuses(statuses) ?? "n/a"
                self?.downloadStatusLabel.text = "Download statuses: \(formattedStatuses)"
                self?.appendLog("storage downloadStatuses emitted: \(formattedStatuses)")
            }
            .store(in: &cancellables)
    }

    @objc
    private func loadBookTapped() {
        guard let startPosition = readDouble(from: startPositionField, fieldName: "start position") else {
            return
        }

        Task { @MainActor in
            guard let checkout = await ensureDemoAudiobookCheckout() else { return }

            do {
                try WeDoBooksFacade.shared
                    .headlessAudioPlayer
                    .loadBook(book: checkout, startPosition: startPosition)
                checkoutLabel.text = "Checkout: \(checkout.title) (\(checkout.materialId))"
                setLoadControlsEnabled(false)
                appendLog("loadBook succeeded (isbn: \(checkout.materialId), start: \(startPosition))")
            } catch {
                appendLog("loadBook failed: \(error)")
            }
        }
    }

    @objc
    private func playTapped() {
        do {
            try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .play()
            appendLog("play() called")
        } catch {
            appendLog("play() failed: \(error)")
        }
    }

    @objc
    private func pauseTapped() {
        do {
            try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .pause()
            appendLog("pause() called")
        } catch {
            appendLog("pause() failed: \(error)")
        }
    }

    @objc
    private func seekTapped() {
        guard let seconds = readDouble(from: seekPositionField, fieldName: "seek target") else {
            return
        }

        do {
            try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .seek(to: seconds)
            appendLog("seek(to:) called with \(seconds)")
        } catch {
            appendLog("seek(to:) failed: \(error)")
        }
    }

    @objc
    private func setRateTapped() {
        guard let rate = readFloat(from: playbackRateField, fieldName: "playback rate") else {
            return
        }

        do {
            try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .setRate(multiplier: rate)
            appendLog("setRate(multiplier:) called with \(rate)")
        } catch {
            appendLog("setRate(multiplier:) failed: \(error)")
        }
    }

    @objc
    private func refreshMetricsTapped() {
        refreshMetrics(logResult: true)
    }

    @objc
    private func downloadTapped() {
        Task { @MainActor in
            guard let checkout = await ensureDemoAudiobookCheckout() else { return }

            do {
                try WeDoBooksFacade.shared
                    .storageOperations
                    .download(book: checkout)
                appendLog("download(book:) requested")
            } catch {
                appendLog("download(book:) failed: \(error)")
            }
        }
    }

    @objc
    private func removeDownloadTapped() {
        Task { @MainActor in
            guard let checkout = await ensureDemoAudiobookCheckout() else { return }

            do {
                try WeDoBooksFacade.shared
                    .storageOperations
                    .removeDownload(isbn: checkout.materialId)
                appendLog("removeDownload(isbn:) succeeded")
            } catch {
                appendLog("removeDownload(isbn:) failed: \(error)")
            }
        }
    }

    @objc
    private func downloadStatusTapped() {
        Task { @MainActor in
            guard let checkout = await ensureDemoAudiobookCheckout() else { return }

            do {
                let status = try WeDoBooksFacade.shared
                    .storageOperations
                    .downloadStatus(book: checkout)
                downloadStatusLabel.text = "Download statuses: \(checkout.materialId): \(status)"
                appendLog("downloadStatus(book:) -> \(status)")
            } catch {
                appendLog("downloadStatus(book:) failed: \(error)")
            }
        }
    }

    @MainActor
    private func ensureDemoAudiobookCheckout() async -> Checkout? {
        if let audiobookCheckout {
            return audiobookCheckout
        }

        appendLog("requesting checkout for audiobook ISBN \(Constants.demoAudiobookISBN)")
        let checkoutResult = await WeDoBooksFacade.shared
            .bookOperations
            .checkoutBook(with: Constants.demoAudiobookISBN)

        switch checkoutResult {
        case .success(let checkout):
            audiobookCheckout = checkout
            appendLog("checkout loaded for ISBN \(checkout.materialId)")
            return checkout
        case .failure(let error):
            appendLog("checkout failed: \(error)")
            return nil
        }
    }

    private func refreshMetrics(logResult: Bool, logErrors: Bool = true) {
        do {
            let position = try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .currentPosition()
            let duration = try WeDoBooksFacade.shared
                .headlessAudioPlayer
                .duration()

            positionLabel.text = "Position: \(String(format: "%.2f", position)) s"
            durationLabel.text = "Duration: \(String(format: "%.2f", duration)) s"

            if logResult {
                appendLog("currentPosition/duration refreshed (\(position), \(duration))")
            }
        } catch {
            if logErrors {
                appendLog("currentPosition/duration failed: \(error)")
            }
        }
    }

    private func readDouble(from field: UITextField, fieldName: String) -> Double? {
        guard let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            appendLog("invalid \(fieldName): value is empty")
            return nil
        }

        guard let value = Double(text) else {
            appendLog("invalid \(fieldName): '\(text)' is not a number")
            return nil
        }

        return value
    }

    private func readFloat(from field: UITextField, fieldName: String) -> Float? {
        guard let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            appendLog("invalid \(fieldName): value is empty")
            return nil
        }

        guard let value = Float(text) else {
            appendLog("invalid \(fieldName): '\(text)' is not a number")
            return nil
        }

        return value
    }

    private func formattedDownloadStatuses(_ statuses: [String: StorageDownloadStatus]) -> String {
        guard statuses.isEmpty == false else {
            return "n/a"
        }

        return statuses.keys.sorted().compactMap { isbn in
            guard let status = statuses[isbn] else { return nil }
            return "\(isbn): \(status)"
        }
        .joined(separator: ", ")
    }

    private func appendLog(_ message: String) {
        print(message)

        if eventLogView.text.isEmpty {
            eventLogView.text = message
        } else {
            eventLogView.text.append("\n\(message)")
        }

        let location = max(eventLogView.text.count - 1, 0)
        eventLogView.scrollRangeToVisible(NSRange(location: location, length: 1))
    }

    private func setLoadControlsEnabled(_ isEnabled: Bool) {
        loadBookButton.isEnabled = isEnabled
        startPositionField.isEnabled = isEnabled
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let fieldFrameInScroll = scrollView.convert(textField.bounds, from: textField)
            let targetRect = fieldFrameInScroll.insetBy(dx: 0, dy: -Constants.keyboardScrollPadding)
            scrollView.scrollRectToVisible(targetRect, animated: true)
        }
    }

    private func makeButtonRow(buttons: [UIButton]) -> UIStackView {
        let result = UIStackView(arrangedSubviews: buttons)
        result.axis = .horizontal
        result.spacing = 12
        result.distribution = .fillEqually

        buttons.forEach {
            $0.heightAnchor.constraint(equalToConstant: Constants.controlHeight).isActive = true
        }

        return result
    }

    private static func makeSectionLabel(_ text: String) -> UILabel {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        result.text = text
        result.textColor = .label
        return result
    }

    private static func makeStatusLabel(_ text: String) -> UILabel {
        let result = UILabel()
        result.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        result.textColor = .secondaryLabel
        result.numberOfLines = 0
        result.text = text
        return result
    }

    private static func makeNumberField(placeholder: String, defaultValue: String) -> UITextField {
        let result = UITextField()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.borderStyle = .roundedRect
        result.keyboardType = .decimalPad
        result.placeholder = placeholder
        result.text = defaultValue
        return result
    }
}
