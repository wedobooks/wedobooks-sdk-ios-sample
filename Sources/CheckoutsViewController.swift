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
    }

    private var cancellables: Set<AnyCancellable> = []
    private var ebookCheckout: Checkout?
    private var audiobookCheckout: Checkout?
    private var ebookDownloadState: DownloadUIState = .notDownloaded
    private var audiobookDownloadState: DownloadUIState = .notDownloaded

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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupViewHierarchy()
        refreshInitialDownloadStatuses()
        configureEbookEntry()
        configureAudiobookEntry()
        observeCheckouts()
        observeDownloadStatuses()
    }

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

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
            isbn: currentEnv.ebookIsbn,
            title: ebookCheckout?.title,
            author: ebookCheckout.flatMap { formattedAuthors($0.author) }
        )
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
            isbn: currentEnv.audioBookIsbn,
            title: audiobookCheckout?.title,
            author: audiobookCheckout.flatMap { formattedAuthors($0.author) }
        )
        audiobookEntryView.setSections([
            BookEntryView.Section(title: "CHECKOUT", buttons: [
                BookEntryView.ButtonModel(title: "Play (SDK player)") { [weak self] in
                    self?.openAudiobook()
                },
                BookEntryView.ButtonModel(title: "Play (headless · custom UI)") { [weak self] in
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
        }
    }

    private func observeCheckouts() {
        do {
            try WeDoBooksFacade.shared
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
                .store(in: &cancellables)
        } catch {
            print("observeCheckouts threw: \(error)")
        }
    }

    private func applyCheckouts(_ checkouts: [Checkout]) {
        if let ebook = checkouts.first(where: { $0.materialId == currentEnv.ebookIsbn && $0.type == .ebook }) {
            ebookCheckout = ebook
            configureEbookEntry()
        }

        if let audiobook = checkouts.first(where: { $0.materialId == currentEnv.audioBookIsbn && $0.type == .audiobook }) {
            audiobookCheckout = audiobook
            configureAudiobookEntry()
        }
    }

    private func formattedAuthors(_ authors: [String]) -> String? {
        let nonEmpty = authors.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else { return nil }
        return nonEmpty.joined(separator: ", ")
    }

    private func refreshInitialDownloadStatuses() {
        if let isDownloaded = try? WeDoBooksFacade.shared.storageOperations.isBookDownloaded(isbn: currentEnv.ebookIsbn) {
            ebookDownloadState = isDownloaded ? .downloaded : .notDownloaded
        }
        if let isDownloaded = try? WeDoBooksFacade.shared.storageOperations.isBookDownloaded(isbn: currentEnv.audioBookIsbn) {
            audiobookDownloadState = isDownloaded ? .downloaded : .notDownloaded
        }
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
        let newEbook = mapDownloadUIState(statuses[currentEnv.ebookIsbn])
        let newAudiobook = mapDownloadUIState(statuses[currentEnv.audioBookIsbn])

        if newEbook != ebookDownloadState {
            ebookDownloadState = newEbook
            configureEbookEntry()
        }
        if newAudiobook != audiobookDownloadState {
            audiobookDownloadState = newAudiobook
            configureAudiobookEntry()
        }
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
        case .notDownloaded, .failure, .cancel:
            return .notDownloaded
        }
    }

    func reenableActions() {
        ebookEntryView.setActionsEnabled(true)
        audiobookEntryView.setActionsEnabled(true)
    }

    // MARK: - Actions

    private func openEbook() {
        ebookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let result = await ensureCheckout(isbn: currentEnv.ebookIsbn, kind: .ebook)
            guard let checkout = result else {
                ebookEntryView.setActionsEnabled(true)
                return
            }
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: presentingHost())
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
            guard let checkout = await ensureCheckout(isbn: currentEnv.ebookIsbn, kind: .ebook) else {
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
            try WeDoBooksFacade.shared.storageOperations.removeDownload(isbn: currentEnv.ebookIsbn)
            ebookDownloadState = .notDownloaded
            configureEbookEntry()
        } catch {
            print("removeDownload(isbn:) for ebook failed: \(error)")
        }
    }

    private func openEbookSample() {
        ebookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openSample(for: currentEnv.ebookIsbn, format: .ebook, presentedBy: presentingHost())
            } catch {
                print("openSample (.ebook) failed: \(error)")
                ebookEntryView.setActionsEnabled(true)
            }
        }
    }

    private func openAudiobook() {
        audiobookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            let result = await ensureCheckout(isbn: currentEnv.audioBookIsbn, kind: .audiobook)
            guard let checkout = result else {
                audiobookEntryView.setActionsEnabled(true)
                return
            }
            do {
                let coverUrl = URL(string: "https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1394988109i/22034.jpg")!
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: presentingHost(), customCover: .url(coverUrl))
            } catch {
                print("openCheckout (audiobook) failed: \(error)")
                audiobookEntryView.setActionsEnabled(true)
            }
        }
    }

    private func openHeadless() {
        let vc = HeadlessAudiobookViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func downloadAudiobook() {
        audiobookDownloadState = .downloading(percent: nil)
        configureAudiobookEntry()
        Task { @MainActor in
            guard let checkout = await ensureCheckout(isbn: currentEnv.audioBookIsbn, kind: .audiobook) else {
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
            try WeDoBooksFacade.shared.storageOperations.removeDownload(isbn: currentEnv.audioBookIsbn)
            audiobookDownloadState = .notDownloaded
            configureAudiobookEntry()
        } catch {
            print("removeDownload(isbn:) for audiobook failed: \(error)")
        }
    }

    private func openAudiobookSample() {
        audiobookEntryView.setActionsEnabled(false)
        Task { @MainActor in
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openSample(for: currentEnv.audioBookIsbn, format: .audiobook, presentedBy: presentingHost())
            } catch {
                print("openSample (.audiobook) failed: \(error)")
                audiobookEntryView.setActionsEnabled(true)
            }
        }
    }

    @MainActor
    private func ensureCheckout(isbn: String, kind: MaterialType) async -> Checkout? {
        let cached = (kind == .ebook) ? ebookCheckout : audiobookCheckout
        if let cached, cached.materialId == isbn { return cached }

        let result = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: isbn)
        switch result {
        case .success(let checkout):
            if kind == .ebook {
                ebookCheckout = checkout
            } else {
                audiobookCheckout = checkout
            }
            return checkout
        case .failure(let error):
            print("checkoutBook for \(isbn) failed: \(error)")
            return nil
        }
    }

    private func presentingHost() -> UIViewController {
        navigationController ?? self
    }
}
