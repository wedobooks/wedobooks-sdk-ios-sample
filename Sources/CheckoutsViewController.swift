//
//  CheckoutsViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

final class CheckoutsViewController: UIViewController {
    private enum DownloadUIState: Equatable {
        case notDownloaded
        case downloading(percent: Int?)
        case downloaded
        case outOfDiskSpace
    }

    private var cancellables: Set<AnyCancellable> = []
    private var checkoutsCancellable: AnyCancellable?
    private var checkouts: [Checkout] = []
    private var ebookCheckout: Checkout? {
        checkout(isbn: ebookEntryView.isbn, type: .ebook)
    }
    private var audiobookCheckout: Checkout? {
        checkout(isbn: audiobookEntryView.isbn, type: .audiobook)
    }
    private var ebookDownloadState: DownloadUIState = .notDownloaded
    private var audiobookDownloadState: DownloadUIState = .notDownloaded
    // Per ISBN, so the out-of-storage alert shows once per failure rather than on every emission.
    private var lastDownloadStatuses: [String: StorageDownloadStatus] = [:]
    // Latest emission from `downloadStatuses`, so an ISBN edit can look up the new book's state.
    private var downloadStatuses: [String: StorageDownloadStatus] = [:]

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        result.contentInset.bottom = 24
        result.verticalScrollIndicatorInsets.bottom = 24
        return result
    }()

    private let contentStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 32
        result.alignment = .fill
        return result
    }()

    private let ebookEntryView = BookEntryView()
    private let audiobookEntryView = BookEntryView()

    private lazy var currentCheckoutsButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "All checkouts"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.heightAnchor.constraint(equalToConstant: 50).isActive = true
        result.addTarget(self, action: #selector(showCurrentCheckouts), for: .touchUpInside)
        return result
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupViewHierarchy()
        refreshDownloadStates()
        configureEbookEntry()
        configureAudiobookEntry()
        ebookEntryView.onIsbnChange = { [weak self] in
            guard let self else { return }
            ebookDownloadState = downloadState(isbn: ebookEntryView.isbn)
            configureEbookEntry()
        }
        audiobookEntryView.onIsbnChange = { [weak self] in
            guard let self else { return }
            audiobookDownloadState = downloadState(isbn: audiobookEntryView.isbn)
            configureAudiobookEntry()
        }
        observeDownloadStatuses()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeCheckouts()
    }

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(currentCheckoutsButton)
        contentStack.addArrangedSubview(ebookEntryView)
        contentStack.addArrangedSubview(audiobookEntryView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func configureEbookEntry() {
        ebookEntryView.configureHeader(
            sectionTitle: "Ebook",
            title: ebookCheckout?.title,
            author: ebookCheckout.flatMap { formattedAuthors($0.author) }
        )
        ebookEntryView.setSavedIsbns(SavedValues.ebookIsbns.all()) { [weak self] isbn in
            SavedValues.ebookIsbns.remove(isbn)
            self?.configureEbookEntry()
        }
        ebookEntryView.setSections([
            BookEntryView.Section(title: "CHECKOUT", buttons: [
                BookEntryView.ButtonModel(title: "Read (SDK reader)") { [weak self] in
                    self?.openEbook()
                },
                downloadButton(for: ebookDownloadState, isEbook: true),
            ]),
            BookEntryView.Section(title: "SAMPLE", buttons: [
                BookEntryView.ButtonModel(title: "Read sample (SDK reader)") { [weak self] in
                    self?.openEbookSample()
                },
            ]),
        ])
    }

    private func configureAudiobookEntry() {
        audiobookEntryView.configureHeader(
            sectionTitle: "Audiobook",
            title: audiobookCheckout?.title,
            author: audiobookCheckout.flatMap { formattedAuthors($0.author) }
        )
        audiobookEntryView.setSavedIsbns(SavedValues.audiobookIsbns.all()) { [weak self] isbn in
            SavedValues.audiobookIsbns.remove(isbn)
            self?.configureAudiobookEntry()
        }
        audiobookEntryView.setSections([
            BookEntryView.Section(title: "CHECKOUT", buttons: [
                BookEntryView.ButtonModel(title: "Play (SDK player)") { [weak self] in
                    self?.openAudiobook()
                },
                BookEntryView.ButtonModel(title: "Play (headless · custom UI)", requiresIsbn: false) { [weak self] in
                    self?.openHeadless()
                },
                downloadButton(for: audiobookDownloadState, isEbook: false),
            ]),
            BookEntryView.Section(title: "SAMPLE", buttons: [
                BookEntryView.ButtonModel(title: "Play sample (SDK player)") { [weak self] in
                    self?.openAudiobookSample()
                },
            ]),
        ])
    }

    private func downloadButton(for state: DownloadUIState, isEbook: Bool) -> BookEntryView.ButtonModel {
        switch state {
        case .notDownloaded:
            return BookEntryView.ButtonModel(title: "Download") { [weak self] in
                if isEbook {
                    self?.downloadEbook()
                } else {
                    self?.downloadAudiobook()
                }
            }
        case .downloading(let percent):
            let title: String
            if let percent {
                title = "Downloading \(percent)%"
            } else {
                title = "Downloading…"
            }
            return BookEntryView.ButtonModel(title: title, isEnabled: false) { }
        case .downloaded:
            return BookEntryView.ButtonModel(title: "Remove download") { [weak self] in
                if isEbook {
                    self?.removeEbookDownload()
                } else {
                    self?.removeAudiobookDownload()
                }
            }
        case .outOfDiskSpace:
            return BookEntryView.ButtonModel(title: "Out of space", isEnabled: false) { }
        }
    }

    private func observeCheckouts() {
        do {
            checkoutsCancellable = try WeDoBooksFacade.shared
                .bookOperations
                .observeCheckouts()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { status in
                    if case .failure(let error) = status {
                        print("observeCheckouts failed: \(error)")
                    }
                }, receiveValue: { [weak self] checkouts in
                    self?.applyCheckouts(checkouts)
                })
        } catch {
            print("observeCheckouts threw: \(error)")
        }
    }

    private func applyCheckouts(_ checkouts: [Checkout]) {
        self.checkouts = checkouts
        configureEbookEntry()
        configureAudiobookEntry()
    }

    private func checkout(isbn: String, type: MaterialType) -> Checkout? {
        checkouts.first { $0.materialId == isbn && $0.type == type }
    }

    private func formattedAuthors(_ authors: [String]) -> String? {
        let nonEmpty = authors.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else { return nil }
        return nonEmpty.joined(separator: ", ")
    }

    private func refreshDownloadStates() {
        ebookDownloadState = downloadState(isbn: ebookEntryView.isbn)
        audiobookDownloadState = downloadState(isbn: audiobookEntryView.isbn)
    }

    /// Prefers the live status for `isbn`, falling back to what's on disk for books without one.
    private func downloadState(isbn: String) -> DownloadUIState {
        if let status = downloadStatuses[isbn] {
            return mapDownloadUIState(status)
        }
        let isDownloaded = (try? WeDoBooksFacade.shared.storageOperations.isBookDownloaded(isbn: isbn)) ?? false
        return isDownloaded ? .downloaded : .notDownloaded
    }

    private func observeDownloadStatuses() {
        WeDoBooksFacade.shared
            .storageOperations
            .downloadStatuses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                self?.applyDownloadStatuses(statuses)
            }
            .store(in: &cancellables)
    }

    private func applyDownloadStatuses(_ statuses: [String: StorageDownloadStatus]) {
        downloadStatuses = statuses
        presentDiskSpaceErrorIfNeeded(isbn: ebookEntryView.isbn, status: statuses[ebookEntryView.isbn])
        presentDiskSpaceErrorIfNeeded(isbn: audiobookEntryView.isbn, status: statuses[audiobookEntryView.isbn])

        let newEbook = downloadState(isbn: ebookEntryView.isbn)
        let newAudiobook = downloadState(isbn: audiobookEntryView.isbn)

        if newEbook != ebookDownloadState {
            ebookDownloadState = newEbook
            configureEbookEntry()
        }
        if newAudiobook != audiobookDownloadState {
            audiobookDownloadState = newAudiobook
            configureAudiobookEntry()
        }
    }

    private func presentDiskSpaceErrorIfNeeded(isbn: String, status: StorageDownloadStatus?) {
        let previous = lastDownloadStatuses[isbn]
        lastDownloadStatuses[isbn] = status

        guard status == .failure(reason: .missingDiskSpace),
              previous != .failure(reason: .missingDiskSpace),
              presentingHost().presentedViewController == nil else { return }

        print("Download of \(isbn) failed: out of storage")
        let alert = UIAlertController(
            title: "Not enough storage",
            message: "The download couldn’t finish because this device is out of storage. Free up space and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingHost().present(alert, animated: true)
    }

    private func mapDownloadUIState(_ status: StorageDownloadStatus?) -> DownloadUIState {
        guard let status else { return .notDownloaded }
        switch status {
        case .initializing:
            return .downloading(percent: nil)
        case .downloading(let progress):
            return .downloading(percent: Int((progress * 100).rounded()))
        case .downloaded:
            return .downloaded
        case .notDownloaded, .cancel:
            return .notDownloaded
        case .failure(let reason):
            switch reason {
            case .missingDiskSpace:
                return .outOfDiskSpace
            case .other:
                return .notDownloaded
            @unknown default:
                return .notDownloaded
            }
        @unknown default:
            return .notDownloaded
        }
    }

    /// Forgets the signed-in user's checkouts so the next user doesn't see (or open) them.
    func clearCheckouts() {
        checkoutsCancellable = nil
        checkouts = []
        guard isViewLoaded else { return }
        configureEbookEntry()
        configureAudiobookEntry()
    }

    func reenableActions() {
        ebookEntryView.setActionsEnabled(true)
        audiobookEntryView.setActionsEnabled(true)
    }

    // MARK: - Actions

    private func openEbook() {
        ebookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let result = await ensureCheckout(isbn: ebookEntryView.isbn, kind: .ebook)
            guard let checkout = result else {
                ebookEntryView.setActionsEnabled(true)
                return
            }
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: presentingHost())
                remember(isbn: checkout.materialId, kind: .ebook)
            } catch {
                print("openCheckout (ebook) failed: \(error)")
                ebookEntryView.setActionsEnabled(true)
            }
        }
    }

    private func downloadEbook() {
        ebookDownloadState = .downloading(percent: nil)
        configureEbookEntry()
        Task { @MainActor in
            guard let checkout = await ensureCheckout(isbn: ebookEntryView.isbn, kind: .ebook) else {
                ebookDownloadState = .notDownloaded
                configureEbookEntry()
                return
            }
            do {
                try WeDoBooksFacade.shared.storageOperations.download(book: checkout)
                print("download(book:) requested for ebook")
            } catch {
                print("download(book:) for ebook failed: \(error)")
                ebookDownloadState = .notDownloaded
                configureEbookEntry()
            }
        }
    }

    private func removeEbookDownload() {
        do {
            try WeDoBooksFacade.shared.storageOperations.removeDownload(isbn: ebookEntryView.isbn)
            ebookDownloadState = .notDownloaded
            configureEbookEntry()
        } catch {
            print("removeDownload(isbn:) for ebook failed: \(error)")
        }
    }

    private func openEbookSample() {
        ebookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let isbn = ebookEntryView.isbn
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openSample(for: isbn, type: .ebook, presentedBy: presentingHost())
                remember(isbn: isbn, kind: .ebook)
            } catch {
                print("openSample (.ebook) failed: \(error)")
                ebookEntryView.setActionsEnabled(true)
            }
        }
    }

    private func openAudiobook() {
        audiobookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let result = await ensureCheckout(isbn: audiobookEntryView.isbn, kind: .audiobook)
            guard let checkout = result else {
                audiobookEntryView.setActionsEnabled(true)
                return
            }
            do {
                let coverUrl = URL(string: "https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1394988109i/22034.jpg")!
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: presentingHost(), customCover: .url(coverUrl))
                remember(isbn: checkout.materialId, kind: .audiobook)
            } catch {
                print("openCheckout (audiobook) failed: \(error)")
                audiobookEntryView.setActionsEnabled(true)
            }
        }
    }

    @objc
    private func showCurrentCheckouts() {
        navigationController?.pushViewController(CurrentCheckoutsViewController(), animated: true)
    }

    private func openHeadless() {
        let vc = HeadlessAudiobookViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func downloadAudiobook() {
        audiobookDownloadState = .downloading(percent: nil)
        configureAudiobookEntry()
        Task { @MainActor in
            guard let checkout = await ensureCheckout(isbn: audiobookEntryView.isbn, kind: .audiobook) else {
                audiobookDownloadState = .notDownloaded
                configureAudiobookEntry()
                return
            }
            do {
                try WeDoBooksFacade.shared.storageOperations.download(book: checkout)
                print("download(book:) requested for audiobook")
            } catch {
                print("download(book:) for audiobook failed: \(error)")
                audiobookDownloadState = .notDownloaded
                configureAudiobookEntry()
            }
        }
    }

    private func removeAudiobookDownload() {
        do {
            try WeDoBooksFacade.shared.storageOperations.removeDownload(isbn: audiobookEntryView.isbn)
            audiobookDownloadState = .notDownloaded
            configureAudiobookEntry()
        } catch {
            print("removeDownload(isbn:) for audiobook failed: \(error)")
        }
    }

    private func openAudiobookSample() {
        audiobookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let isbn = audiobookEntryView.isbn
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openSample(for: isbn, type: .audiobook, presentedBy: presentingHost())
                remember(isbn: isbn, kind: .audiobook)
            } catch {
                print("openSample (.audiobook) failed: \(error)")
                audiobookEntryView.setActionsEnabled(true)
            }
        }
    }

    @MainActor
    private func ensureCheckout(isbn: String, kind: MaterialType) async -> Checkout? {
        if let existing = checkout(isbn: isbn, type: kind) { return existing }

        // The new checkout also arrives through `observeCheckouts()`, which updates the header.
        let result = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: isbn)
        switch result {
        case .success(let checkout):
            remember(isbn: isbn, kind: kind)
            return checkout
        case .failure(let error):
            print("checkoutBook for \(isbn) failed: \(error)")
            presentCheckoutError(error, isbn: isbn)
            return nil
        }
    }

    private func presentCheckoutError(_ error: CheckoutError, isbn: String) {
        guard presentingHost().presentedViewController == nil else { return }
        let alert = UIAlertController(
            title: "Couldn’t check out \(isbn)",
            message: Self.message(for: error),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingHost().present(alert, animated: true)
    }

    private static func message(for error: CheckoutError) -> String {
        switch error {
        case .noUserSignedIn:
            return "Sign in to check out books."
        case .rejected(let quota, let reason):
            return "The loan was rejected (\(reason), quota \(quota))."
        case .unknown:
            return "This book isn’t available for loan right now. It may be possible to reserve it or add it to your wish list."
        case .underlyingError:
            return "Something went wrong. Try again."
        }
    }

    /// Saves an ISBN that was checked out or opened, so its field offers it next time.
    private func remember(isbn: String, kind: MaterialType) {
        if kind == .ebook {
            SavedValues.ebookIsbns.save(isbn)
            configureEbookEntry()
        } else {
            SavedValues.audiobookIsbns.save(isbn)
            configureAudiobookEntry()
        }
    }

    private func presentingHost() -> UIViewController {
        navigationController ?? self
    }
}
