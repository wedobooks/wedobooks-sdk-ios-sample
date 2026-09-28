//
//  CurrentCheckoutsViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 23/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

final class CurrentCheckoutsViewController: UITableViewController {
    private static let cellIdentifier = "CheckoutCell"

    private var cancellables: Set<AnyCancellable> = []
    private var checkouts: [Checkout] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Current checkouts"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        observeCheckouts()
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
                    self?.checkouts = checkouts.sorted { $0.title < $1.title }
                    self?.tableView.reloadData()
                })
                .store(in: &cancellables)
        } catch {
            print("observeCheckouts threw: \(error)")
        }
    }

    private func open(_ checkout: Checkout) {
        tableView.isUserInteractionEnabled = false
        Task { @MainActor in
            defer { tableView.isUserInteractionEnabled = true }
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: navigationController ?? self)
                remember(checkout)
            } catch {
                print("openCheckout failed: \(error)")
            }
        }
    }

    private func remember(_ checkout: Checkout) {
        switch checkout.type {
        case .ebook:
            SavedValues.ebookIsbns.save(checkout.materialId)
        case .audiobook:
            SavedValues.audiobookIsbns.save(checkout.materialId)
        default:
            break
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        checkouts.isEmpty ? "No current checkouts" : "Tap a checkout to open it"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        checkouts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let checkout = checkouts[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = checkout.title
        content.secondaryText = "\(label(for: checkout.type)) · \(checkout.materialId)\nid: \(checkout.id)"
        content.secondaryTextProperties.numberOfLines = 0
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        open(checkouts[indexPath.row])
    }

    private func label(for type: MaterialType) -> String {
        switch type {
        case .ebook: return "Ebook"
        case .audiobook: return "Audiobook"
        case .podcast: return "Podcast"
        @unknown default: return "Unknown"
        }
    }
}
