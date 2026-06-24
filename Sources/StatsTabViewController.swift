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

    private lazy var contentScrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.showsVerticalScrollIndicator = true
        result.showsHorizontalScrollIndicator = false
        result.alwaysBounceVertical = true
        return result
    }()

    private let contentStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.alignment = .fill
        result.spacing = 20
        return result
    }()

    private let historyHeaderLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "History"
        result.font = .systemFont(ofSize: 20, weight: .bold)
        result.textColor = .label
        result.textAlignment = .center
        return result
    }()

    private lazy var historyScrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isPagingEnabled = true
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.delegate = self
        return result
    }()

    private let historyStack: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .horizontal
        result.alignment = .fill
        result.distribution = .fillEqually
        result.spacing = 0
        return result
    }()

    private let historyPageControl: UIPageControl = {
        let result = UIPageControl()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.currentPageIndicatorTintColor = Theme.primary
        result.pageIndicatorTintColor = UIColor.systemGray3
        result.numberOfPages = 0
        result.isUserInteractionEnabled = false
        return result
    }()

    private let historyEmptyLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "No history yet"
        result.font = .systemFont(ofSize: 15, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        result.isHidden = true
        return result
    }()

    private var pages: [PageModel] = []
    private var historyItems: [HistoryItem] = []
    private var historyTask: Task<Void, Never>?
    // Per-operation debounce sets so a mark-complete in flight does not block a
    // delete (or vice versa) on the same card; they guard against double-taps of
    // the *same* action only.
    private var completingMaterialIds: Set<String> = []
    private var removingMaterialIds: Set<String> = []
    private var mutationTasks: [Task<Void, Never>] = []
    // Materials the user marked complete this session. Keeps the card showing
    // "Completed" across the reload, masking read-after-write lag between the
    // markCompleted callable and the direct Firestore list() read.
    private var completedOverrides: Set<String> = []

    deinit {
        historyTask?.cancel()
        mutationTasks.forEach { $0.cancel() }
    }

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
        loadHistory()
    }

    private lazy var filterStack: UIStackView = {
        let result = UIStackView(arrangedSubviews: [filterButton, clearFilterButton])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.alignment = .center
        result.spacing = 4
        return result
    }()

    private func setupViewHierarchy() {
        view.addSubview(filterStack)
        view.addSubview(contentScrollView)

        contentScrollView.addSubview(contentStack)
        pagesScrollView.addSubview(pagesStack)
        historyScrollView.addSubview(historyStack)

        // emptyStateLabel sits in the stats slot (shown opposite pagesScrollView)
        // so "No stats yet" occupies the pager's place rather than overlaying the
        // independently-rendered history section below it.
        [pagesScrollView, pageControl, emptyStateLabel, historyHeaderLabel, historyScrollView, historyPageControl, historyEmptyLabel]
            .forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(28, after: pageControl)
        contentStack.setCustomSpacing(12, after: historyHeaderLabel)

        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            filterStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 220),
            filterButton.heightAnchor.constraint(equalToConstant: 48),

            contentScrollView.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 20),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),

            pagesScrollView.heightAnchor.constraint(equalTo: pagesStack.heightAnchor),
            pagesStack.topAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: pagesScrollView.contentLayoutGuide.bottomAnchor),

            historyScrollView.heightAnchor.constraint(equalTo: historyStack.heightAnchor),
            historyStack.topAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.topAnchor),
            historyStack.leadingAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.leadingAnchor),
            historyStack.trailingAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.trailingAnchor),
            historyStack.bottomAnchor.constraint(equalTo: historyScrollView.contentLayoutGuide.bottomAnchor),
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

    private func loadHistory() {
        historyTask?.cancel()
        historyTask = Task { @MainActor [weak self] in
            let result = await WeDoBooksFacade.shared.historyOperations.list()
            guard let self, !Task.isCancelled else { return }
            switch result {
            case .success(let page):
                self.historyItems = page.items
                self.completedOverrides.formIntersection(page.items.map(\.materialId))
                self.historyEmptyLabel.text = "No history yet"
            case .failure(let error):
                print("historyOperations.list failed: \(error)")
                self.historyItems = []
                self.historyEmptyLabel.text = Self.emptyMessage(for: error)
            }
            self.renderHistory()
        }
    }

    private static func emptyMessage(for error: HistoryError) -> String {
        switch error {
        case .unsupportedInLibraryMode:
            return "History is unavailable in library mode"
        case .noUserSignedIn:
            return "Sign in to see history"
        default:
            return "Couldn't load history"
        }
    }

    private func markComplete(_ item: HistoryItem) {
        guard completingMaterialIds.insert(item.materialId).inserted else { return }
        let task = Task { @MainActor [weak self] in
            let result = await WeDoBooksFacade.shared.historyOperations.markCompleted(materialId: item.materialId)
            guard let self else { return }
            self.completingMaterialIds.remove(item.materialId)
            switch result {
            case .success:
                self.completedOverrides.insert(item.materialId)
                self.loadHistory()
            case .failure(let error):
                print("historyOperations.markCompleted failed: \(error)")
                self.presentError(title: "Failed to mark as complete", error)
            }
        }
        mutationTasks.append(task)
    }

    private func removeHistory(_ item: HistoryItem) {
        guard removingMaterialIds.insert(item.materialId).inserted else { return }
        let task = Task { @MainActor [weak self] in
            let result = await WeDoBooksFacade.shared.historyOperations.remove(materialId: item.materialId)
            guard let self else { return }
            self.removingMaterialIds.remove(item.materialId)
            switch result {
            case .success:
                self.loadHistory()
            case .failure(let error):
                print("historyOperations.remove failed: \(error)")
                self.presentError(title: "Failed to remove from history", error)
            }
        }
        mutationTasks.append(task)
    }

    private func presentError(title: String, _ error: HistoryError) {
        let alert = UIAlertController(
            title: title,
            message: String(describing: error),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func renderHistory() {
        // Preserve the page the user is on so a mark-complete / remove (which both
        // reload) doesn't snap the pager back to the first card.
        let previousPage = historyPageControl.currentPage
        historyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in historyItems {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.backgroundColor = .clear

            let card = HistoryCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            let isCompleted = item.status == .completed || completedOverrides.contains(item.materialId)
            card.configure(
                item: item,
                isCompleted: isCompleted,
                onMarkComplete: { [weak self] in self?.markComplete(item) },
                onDelete: { [weak self] in self?.removeHistory(item) }
            )
            pageView.addSubview(card)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: pageView.topAnchor, constant: 8),
                card.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -16),
                card.bottomAnchor.constraint(lessThanOrEqualTo: pageView.bottomAnchor, constant: -16),
            ])

            historyStack.addArrangedSubview(pageView)
            pageView.widthAnchor.constraint(equalTo: historyScrollView.frameLayoutGuide.widthAnchor).isActive = true
        }

        let hasHistory = !historyItems.isEmpty
        let targetPage = max(0, min(previousPage, historyItems.count - 1))
        historyPageControl.numberOfPages = historyItems.count
        historyPageControl.currentPage = targetPage
        historyPageControl.isHidden = historyItems.count <= 1
        historyHeaderLabel.isHidden = !hasHistory
        historyScrollView.isHidden = !hasHistory
        historyEmptyLabel.isHidden = hasHistory

        // Restore the scroll offset to the preserved page once the rebuilt content
        // is laid out (bounds.width is 0 before layout, which safely yields .zero).
        historyScrollView.layoutIfNeeded()
        let offsetX = CGFloat(targetPage) * historyScrollView.bounds.width
        historyScrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
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
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x + scrollView.bounds.width / 2) / scrollView.bounds.width)
        if scrollView === pagesScrollView {
            pageControl.currentPage = max(0, min(page, max(0, pages.count - 1)))
        } else if scrollView === historyScrollView {
            historyPageControl.currentPage = max(0, min(page, max(0, historyItems.count - 1)))
        }
    }
}
