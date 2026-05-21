//
//  StatsTabViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

extension StatEntry {
    static let empty = StatEntry(
        audioMinutes: 0,
        ebookMinutes: 0,
        minutesRead: 0,
        audioSeconds: 0,
        ebookSeconds: 0,
        secondsRead: 0,
        wordsRead: 0
    )
}

final class StatsTabViewController: UIViewController {
    private struct PageModel {
        let title: String
        let subtitle: String
        let entry: StatEntry
    }

    private static let dateKeyFormatter: DateFormatter = {
        let result = DateFormatter()
        result.dateFormat = "yyyy-MM-dd"
        return result
    }()

    private var cancellables: Set<AnyCancellable> = []
    private var selectedDate: Date?

    private let filterButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Filter by date"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let clearFilterButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Clear filter"
        config.baseForegroundColor = Theme.primary
        let result = UIButton(configuration: config)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isHidden = true
        return result
    }()

    private lazy var pagesScrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isPagingEnabled = true
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.delegate = self
        return result
    }()

    private let pagesStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .horizontal
        result.alignment = .fill
        result.distribution = .fillEqually
        result.spacing = 0
        return result
    }()

    private let pageControl: UIPageControl = {
        let result = UIPageControl()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.currentPageIndicatorTintColor = Theme.primary
        result.pageIndicatorTintColor = UIColor.systemGray3
        result.numberOfPages = 0
        result.isUserInteractionEnabled = false
        return result
    }()

    private let emptyStateLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "No stats yet"
        result.font = .systemFont(ofSize: 17, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        result.isHidden = true
        return result
    }()

    private var pages: [PageModel] = []

    private lazy var filterStack: UIStackView = {
        let result = UIStackView(arrangedSubviews: [filterButton, clearFilterButton])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.alignment = .center
        result.spacing = 4
        return result
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label

        setupViewHierarchy()
        filterButton.addTarget(self, action: #selector(filterByDateTapped), for: .touchUpInside)
        clearFilterButton.addTarget(self, action: #selector(clearFilterTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPages()
    }

    private func setupViewHierarchy() {
        view.addSubview(filterStack)
        view.addSubview(pagesScrollView)
        view.addSubview(pageControl)
        view.addSubview(emptyStateLabel)
        pagesScrollView.addSubview(pagesStack)

        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            filterStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 220),
            filterButton.heightAnchor.constraint(equalToConstant: 48),

            pagesScrollView.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 20),
            pagesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagesScrollView.heightAnchor.constraint(equalTo: pagesStack.heightAnchor),

            pagesStack.topAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.bottomAnchor),

            pageControl.topAnchor.constraint(equalTo: pagesScrollView.bottomAnchor, constant: 20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func loadPages() {
        cancellables = []

        let year = Calendar.current.component(.year, from: Date())
        let yearString = String(year)

        let yearPublisher = WeDoBooksFacade.shared.userOperations
            .totalStats(year: yearString)
            .prefix(1)

        let checkoutsPublisher: AnyPublisher<[Checkout], Never>
        do {
            checkoutsPublisher = try WeDoBooksFacade.shared
                .bookOperations
                .observeCheckouts()
                .prefix(1)
                .replaceError(with: [])
                .eraseToAnyPublisher()
        } catch {
            print("observeCheckouts threw: \(error)")
            checkoutsPublisher = Just([]).eraseToAnyPublisher()
        }

        Publishers.CombineLatest(yearPublisher, checkoutsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] yearStats, checkouts in
                self?.assemblePages(yearStats: yearStats, yearString: yearString, checkouts: checkouts)
            }
            .store(in: &cancellables)
    }

    private func assemblePages(yearStats: [String: StatEntry], yearString: String, checkouts: [Checkout]) {
        var models: [PageModel] = []
        let dateKey = selectedDate.map { Self.dateKeyFormatter.string(from: $0) }
        let subtitle = dateKey.map { "on \($0)" } ?? "all time"

        let yearEntry: StatEntry
        if let dateKey {
            yearEntry = yearStats[dateKey] ?? .empty
        } else {
            yearEntry = sumStats(yearStats)
        }
        models.append(PageModel(
            title: "Year — \(yearString)",
            subtitle: subtitle,
            entry: yearEntry
        ))

        let group = DispatchGroup()
        var perCheckoutEntries: [(Checkout, StatEntry)] = []
        let queue = DispatchQueue(label: "stats.assemble")

        let sortedCheckouts = checkouts.sorted { $0.title < $1.title }
        for checkout in sortedCheckouts {
            group.enter()
            var local: AnyCancellable?
            local = WeDoBooksFacade.shared.userOperations
                .totalStats(checkoutId: checkout.id)
                .prefix(1)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] stats in
                    guard let self else { group.leave(); return }
                    let entry: StatEntry
                    if let dateKey {
                        entry = stats[dateKey] ?? .empty
                    } else {
                        entry = sumStats(stats)
                    }
                    queue.sync {
                        perCheckoutEntries.append((checkout, entry))
                    }
                    group.leave()
                    local?.cancel()
                }
            if let local {
                cancellables.insert(local)
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            for (checkout, entry) in perCheckoutEntries {
                models.append(PageModel(
                    title: checkout.title,
                    subtitle: subtitle,
                    entry: entry
                ))
            }
            self.pages = models
            self.renderPages()
        }
    }

    private func renderPages() {
        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for model in pages {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.backgroundColor = .clear

            let card = StatsCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.configure(title: model.title, subtitle: model.subtitle, entry: model.entry)
            pageView.addSubview(card)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 8),
                card.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -16),
                card.bottomAnchor.constraint(lessThanOrEqualTo: pageView.bottomAnchor, constant: -16),
            ])

            pagesStack.addArrangedSubview(pageView)
            pageView.widthAnchor.constraint(equalTo: pagesScrollView.frameLayoutGuide.widthAnchor).isActive = true
        }

        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.isHidden = pages.count <= 1
        emptyStateLabel.isHidden = !pages.isEmpty
        pagesScrollView.isHidden = pages.isEmpty
        pagesScrollView.setContentOffset(.zero, animated: false)
    }

    private func sumStats(_ stats: [String: StatEntry]) -> StatEntry {
        stats.reduce(StatEntry.empty) { partial, kv in
            let entry = kv.value
            return StatEntry(
                audioMinutes: partial.audioMinutes + entry.audioMinutes,
                ebookMinutes: partial.ebookMinutes + entry.ebookMinutes,
                minutesRead: partial.minutesRead + entry.minutesRead,
                audioSeconds: partial.audioSeconds + entry.audioSeconds,
                ebookSeconds: partial.ebookSeconds + entry.ebookSeconds,
                secondsRead: partial.secondsRead + entry.secondsRead,
                wordsRead: partial.wordsRead + entry.wordsRead
            )
        }
    }

    @objc
    private func filterByDateTapped() {
        let pickerVC = DatePickerViewController(initialDate: selectedDate ?? .now) { [weak self] datePicked in
            self?.applySelectedDate(datePicked)
        }
        pickerVC.modalPresentationStyle = .formSheet
        present(pickerVC, animated: true)
    }

    @objc
    private func clearFilterTapped() {
        applySelectedDate(nil)
    }

    private func applySelectedDate(_ date: Date?) {
        selectedDate = date
        if let date {
            let formatted = Self.dateKeyFormatter.string(from: date)
            filterButton.configuration = .standardConfiguration(for: formatted)
        } else {
            filterButton.configuration = .standardConfiguration(for: "Filter by date")
        }
        clearFilterButton.isHidden = (date == nil)
        loadPages()
    }
}

extension StatsTabViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === pagesScrollView, scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x + scrollView.bounds.width / 2) / scrollView.bounds.width)
        pageControl.currentPage = max(0, min(page, max(0, pages.count - 1)))
    }
}
