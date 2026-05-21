//
//  DownloadedBooksViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 25/07/2025.
//  Copyright © 2025 WeDoBooks A/S. All rights reserved.
//

import UIKit
import WeDoBooksSDK

final class DownloadedBooksViewController: UIViewController {
    private let countLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.font = .systemFont(ofSize: 16, weight: .regular)
        result.textColor = .secondaryLabel
        return result
    }()

    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Refresh", for: .normal)
        button.setTitleColor(Theme.primary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        result.showsVerticalScrollIndicator = false
        return result
    }()

    private let listStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 12
        result.alignment = .fill
        return result
    }()

    private let emptyStateLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "No downloads on this device"
        result.font = .systemFont(ofSize: 16, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        result.isHidden = true
        return result
    }()

    private var isbns: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Downloaded books"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.hidesBackButton = true

        setupViewHierarchy()
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        reloadDownloads()
    }

    private func setupViewHierarchy() {
        view.addSubview(countLabel)
        view.addSubview(refreshButton)
        view.addSubview(scrollView)
        view.addSubview(emptyStateLabel)
        scrollView.addSubview(listStack)

        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            refreshButton.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            listStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            listStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            listStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            listStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            listStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func reloadDownloads() {
        let books = (try? WeDoBooksFacade.shared.storageOperations.getAllDownloadedBooks()) ?? []
        isbns = books.sorted()
        renderRows()
    }

    private func renderRows() {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for isbn in isbns {
            let row = DownloadedBookRowView(isbn: isbn)
            row.onTrashTapped = { [weak self] tappedIsbn in
                self?.removeDownload(isbn: tappedIsbn)
            }
            listStack.addArrangedSubview(row)
        }

        countLabel.text = countDescription(isbns.count)
        emptyStateLabel.isHidden = !isbns.isEmpty
        scrollView.isHidden = isbns.isEmpty
    }

    private func countDescription(_ count: Int) -> String {
        switch count {
        case 0: return "No books on this device"
        case 1: return "1 book on this device"
        default: return "\(count) books on this device"
        }
    }

    private func removeDownload(isbn: String) {
        do {
            try WeDoBooksFacade.shared.storageOperations.removeDownload(isbn: isbn)
            reloadDownloads()
        } catch {
            print("removeDownload(isbn:) failed for \(isbn): \(error)")
        }
    }

    @objc
    private func refreshTapped() {
        reloadDownloads()
    }

    @objc
    private func closeTapped() {
        navigationController?.popViewController(animated: true)
    }
}

private final class DownloadedBookRowView: UIView {
    private let isbn: String
    var onTrashTapped: ((String) -> Void)?

    private let isbnLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 17, weight: .semibold)
        result.textColor = .label
        result.numberOfLines = 1
        return result
    }()

    private let subtitleLabel: UILabel = {
        let result = UILabel()
        result.text = "Stored locally"
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        return result
    }()

    private lazy var trashButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "trash")
        config.baseForegroundColor = Theme.primary
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(trashTapped), for: .touchUpInside)
        return button
    }()

    init(isbn: String) {
        self.isbn = isbn
        super.init(frame: .zero)
        setupViewHierarchy()
        Theme.applyCardStyle(to: self)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        isbnLabel.text = "ISBN \(isbn)"

        let textStack = UIStackView(arrangedSubviews: [isbnLabel, subtitleLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [textStack, trashButton])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fill
        row.spacing = 12
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trashButton.setContentHuggingPriority(.required, for: .horizontal)
        trashButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    @objc
    private func trashTapped() {
        onTrashTapped?(isbn)
    }
}
