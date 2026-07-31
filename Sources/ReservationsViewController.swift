//
//  ReservationsViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Martin An Vo on 20/07/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

final class ReservationsViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        result.keyboardDismissMode = .onDrag
        result.contentInset.bottom = 24
        return result
    }()

    private let contentStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.spacing = 12
        result.alignment = .fill
        return result
    }()

    private let statusLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 13, weight: .medium)
        result.textColor = Theme.primary
        result.numberOfLines = 0
        result.isHidden = true
        return result
    }()

    private let isbnField: UITextField = {
        let result = UITextField()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.borderStyle = .roundedRect
        result.placeholder = "ISBN"
        result.autocapitalizationType = .none
        result.autocorrectionType = .no
        result.clearButtonMode = .whileEditing
        return result
    }()

    private lazy var reserveButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Reserve"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.heightAnchor.constraint(equalToConstant: 44).isActive = true
        result.addAction(UIAction { [weak self] _ in self?.reserveTapped() }, for: .touchUpInside)
        return result
    }()

    private let reserveResultLabel: UILabel = {
        let result = UILabel()
        result.font = .systemFont(ofSize: 13)
        result.textColor = .secondaryLabel
        result.numberOfLines = 0
        return result
    }()

    private let reservationsHeader = ReservationsViewController.makeSectionHeader("Reservations (0)")
    private let reservationsContainer = ReservationsViewController.makeContainerStack()
    private let offersHeader = ReservationsViewController.makeSectionHeader("Offers (0)")
    private let offersContainer = ReservationsViewController.makeContainerStack()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        isbnField.text = currentEnv.reservationIsbn ?? currentEnv.ebookIsbn
        setupViewHierarchy()
        renderReservations([])
        renderOffers([])
        observeReservations()
        observeReservationOffers()
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let reserveTitle = UILabel()
        reserveTitle.text = "Reserve a book"
        reserveTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        reserveTitle.textColor = .label

        let reserveCard = makeCard([reserveTitle, isbnField, reserveButton, reserveResultLabel])

        contentStack.addArrangedSubview(statusLabel)
        contentStack.addArrangedSubview(reserveCard)
        contentStack.addArrangedSubview(reservationsHeader)
        contentStack.addArrangedSubview(reservationsContainer)
        contentStack.addArrangedSubview(offersHeader)
        contentStack.addArrangedSubview(offersContainer)
        contentStack.setCustomSpacing(20, after: reserveCard)
        contentStack.setCustomSpacing(20, after: reservationsContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    // MARK: - Observation

    private func observeReservations() {
        do {
            try WeDoBooksFacade.shared
                .reservationOperations
                .observeReservations()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] reservations in
                    self?.renderReservations(reservations)
                }
                .store(in: &cancellables)
        } catch {
            print("observeReservations threw: \(error)")
        }
    }

    private func observeReservationOffers() {
        do {
            try WeDoBooksFacade.shared
                .reservationOperations
                .observeReservationOffers()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] offers in
                    self?.renderOffers(offers)
                }
                .store(in: &cancellables)
        } catch {
            print("observeReservationOffers threw: \(error)")
        }
    }

    // MARK: - Rendering

    private func renderReservations(_ reservations: [Reservation]) {
        reservationsHeader.text = "Reservations (\(reservations.count))".uppercased()
        reservationsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if reservations.isEmpty {
            reservationsContainer.addArrangedSubview(Self.makeEmptyLabel("No reservations yet"))
        } else {
            reservations.forEach { reservationsContainer.addArrangedSubview(makeReservationCard($0)) }
        }
    }

    private func renderOffers(_ offers: [ReservationOffer]) {
        offersHeader.text = "Offers (\(offers.count))".uppercased()
        offersContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if offers.isEmpty {
            offersContainer.addArrangedSubview(Self.makeEmptyLabel("No active offers"))
        } else {
            offers.forEach { offersContainer.addArrangedSubview(makeOfferCard($0)) }
        }
    }

    // MARK: - Actions

    private func reserveTapped() {
        let isbn = (isbnField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isbn.isEmpty else { return }
        view.endEditing(true)
        reserveButton.isEnabled = false
        reserveResultLabel.text = "Reserving…"

        Task { @MainActor in
            let result = await WeDoBooksFacade.shared.reservationOperations.reserveBook(isbn: isbn)
            switch result {
            case .success(let response):
                var text = String(describing: response.canLoan)
                if let message = response.message, !message.isEmpty {
                    text += " · \(message)"
                }
                reserveResultLabel.text = text
            case .failure(let error):
                reserveResultLabel.text = "Error: \(error)"
            }
            reserveButton.isEnabled = true
        }
    }

    private func deleteReservation(_ reservation: Reservation, buttons: [UIButton]) {
        buttons.forEach { $0.isEnabled = false }
        Task { @MainActor in
            defer { buttons.forEach { $0.isEnabled = true } }
            let result = await WeDoBooksFacade.shared.reservationOperations.removeReservation(isbn: reservation.materialId)
            switch result {
            case .success(let removed):
                showStatus(removed ? "Reservation deleted" : "Delete returned false")
            case .failure(let error):
                showStatus("Delete failed: \(error)")
            }
        }
    }

    private func acceptOffer(_ offer: ReservationOffer, buttons: [UIButton]) {
        buttons.forEach { $0.isEnabled = false }
        Task { @MainActor in
            defer { buttons.forEach { $0.isEnabled = true } }
            let result = await WeDoBooksFacade.shared.reservationOperations.acceptReservationOffer(offerId: offer.id)
            switch result {
            case .success(let response):
                if response.success {
                    showStatus("Offer accepted — loan \(response.loanId ?? "-")")
                } else {
                    var text = "Offer not accepted"
                    if let canLoan = response.canLoan {
                        text += " · \(String(describing: canLoan))"
                    }
                    if let quotaReject = response.quotaReject {
                        text += " (quota \(quotaReject.quota))"
                    }
                    showStatus(text)
                }
            case .failure(let error):
                showStatus("Accept failed: \(error)")
            }
        }
    }

    private func cancelOffer(_ offer: ReservationOffer, buttons: [UIButton]) {
        buttons.forEach { $0.isEnabled = false }
        Task { @MainActor in
            defer { buttons.forEach { $0.isEnabled = true } }
            let result = await WeDoBooksFacade.shared.reservationOperations.removeReservation(isbn: offer.materialId)
            switch result {
            case .success(let removed):
                showStatus(removed ? "Offer cancelled (reservation removed)" : "Cancel returned false")
            case .failure(let error):
                showStatus("Cancel failed: \(error)")
            }
        }
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.isHidden = false
    }

    // MARK: - Card builders

    private func makeReservationCard(_ reservation: Reservation) -> UIView {
        var rows: [UIView] = [
            Self.makeCardTitle("ISBN \(reservation.materialId)"),
            Self.makeMetaRow("Type", String(describing: reservation.type)),
            Self.makeMetaRow("Material", String(describing: reservation.materialType)),
            Self.makeMetaRow("Loan date", dateFormatter.string(from: reservation.loanDate)),
        ]
        if reservation.wordCount > 0 {
            rows.append(Self.makeMetaRow("Words", "\(reservation.wordCount)"))
        }
        if reservation.duration > 0 {
            rows.append(Self.makeMetaRow("Duration", "\(reservation.duration)s"))
        }

        let deleteButton = makeActionButton("Delete reservation", destructive: true)
        deleteButton.addAction(UIAction { [weak self, weak deleteButton] _ in
            self?.deleteReservation(reservation, buttons: [deleteButton].compactMap { $0 })
        }, for: .touchUpInside)
        rows.append(deleteButton)

        return makeCard(rows)
    }

    private func makeOfferCard(_ offer: ReservationOffer) -> UIView {
        var rows: [UIView] = [
            Self.makeCardTitle("ISBN \(offer.materialId)"),
            Self.makeMetaRow("Status", String(describing: offer.status)),
            Self.makeMetaRow("Expires", dateFormatter.string(from: offer.expiresAt)),
        ]

        let acceptButton = makeActionButton("Accept offer", destructive: false)
        let cancelButton = makeActionButton("Cancel offer", destructive: true)
        acceptButton.addAction(UIAction { [weak self, weak acceptButton, weak cancelButton] _ in
            self?.acceptOffer(offer, buttons: [acceptButton, cancelButton].compactMap { $0 })
        }, for: .touchUpInside)
        cancelButton.addAction(UIAction { [weak self, weak acceptButton, weak cancelButton] _ in
            self?.cancelOffer(offer, buttons: [acceptButton, cancelButton].compactMap { $0 })
        }, for: .touchUpInside)
        rows.append(acceptButton)
        rows.append(cancelButton)

        return makeCard(rows)
    }

    private func makeCard(_ arrangedSubviews: [UIView]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        Theme.applyCardStyle(to: card)

        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        return card
    }

    private func makeActionButton(_ title: String, destructive: Bool) -> UIButton {
        var config = UIButton.Configuration.standardConfiguration(for: title)
        if destructive {
            config.baseBackgroundColor = Theme.destructiveFill
            config.baseForegroundColor = Theme.destructiveText
        }
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    // MARK: - Static view helpers

    private static func makeContainerStack() -> UIStackView {
        let result = UIStackView()
        result.axis = .vertical
        result.spacing = 12
        result.alignment = .fill
        return result
    }

    private static func makeSectionHeader(_ text: String) -> UILabel {
        let result = UILabel()
        result.text = text.uppercased()
        result.font = .systemFont(ofSize: 13, weight: .semibold)
        result.textColor = Theme.primary
        return result
    }

    private static func makeEmptyLabel(_ text: String) -> UILabel {
        let result = UILabel()
        result.text = text
        result.font = .systemFont(ofSize: 15)
        result.textColor = .secondaryLabel
        return result
    }

    private static func makeCardTitle(_ text: String) -> UILabel {
        let result = UILabel()
        result.text = text
        result.font = .systemFont(ofSize: 15, weight: .semibold)
        result.textColor = .label
        result.numberOfLines = 0
        return result
    }

    private static func makeMetaRow(_ label: String, _ value: String) -> UIView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.textColor = .secondaryLabel
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        labelView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 13, weight: .semibold)
        valueView.textColor = .label
        valueView.textAlignment = .right
        valueView.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [labelView, valueView])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .firstBaseline
        row.distribution = .fill
        return row
    }
}
