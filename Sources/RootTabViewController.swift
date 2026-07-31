//
//  RootTabViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

protocol RootTabViewControllerDelegate: AnyObject {
    func userDidLogout()
}

final class RootTabViewController: UIViewController {
    enum Tab: Int, CaseIterable {
        case checkouts
        case stats
        case reservations
        case settings

        var title: String {
            switch self {
            case .checkouts: return "Checkouts"
            case .stats: return "Stats"
            case .reservations: return "Reservations"
            case .settings: return "Settings"
            }
        }
    }

    private var cancellables: Set<AnyCancellable> = []
    private var cancellablesForUser: Set<AnyCancellable> = []

    weak var delegate: RootTabViewControllerDelegate?

    // MARK: - Header

    private let titleLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "WeDoBooks SDK Sample"
        result.font = .systemFont(ofSize: 22, weight: .bold)
        result.textAlignment = .center
        return result
    }()

    private let subtitleLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "\(currentEnv.name) · \(currentEnv.modeDisplayName)"
        result.font = .systemFont(ofSize: 14, weight: .regular)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        return result
    }()

    private lazy var tabBar: SegmentedTabBar = {
        let result = SegmentedTabBar(titles: visibleTabs.map(\.title))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.onSelectionChange = { [weak self] index in
            self?.activate(tabIndex: index)
        }
        return result
    }()

    private let contentContainer: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let easyAccessView: EasyAccessView = {
        let result = EasyAccessView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private lazy var easyAccessCollapsedHeightConstraint: NSLayoutConstraint =
        easyAccessView.heightAnchor.constraint(equalToConstant: 0)

    // MARK: - Tabs

    private lazy var checkoutsViewController = CheckoutsViewController()
    private lazy var reservationsViewController = ReservationsViewController()
    private lazy var statsViewController = StatsTabViewController()
    private lazy var settingsViewController = SettingsViewController()

    private var isLibraryMode: Bool {
        if case .library = currentEnv.mode { return true }
        return false
    }

    private var visibleTabs: [Tab] {
        Tab.allCases.filter { $0 != .reservations || isLibraryMode }
    }

    private func controller(for tab: Tab) -> UIViewController {
        switch tab {
        case .checkouts: return checkoutsViewController
        case .reservations: return reservationsViewController
        case .stats: return statsViewController
        case .settings: return settingsViewController
        }
    }

    private var orderedTabControllers: [UIViewController] {
        visibleTabs.map(controller(for:))
    }

    private var activeTabIndex: Int = 0

    // MARK: - View lifecycle

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        settingsViewController.delegate = self

        setupViewHierarchy()
        easyAccessView.delegate = self
        setEasyAccessVisible(false)

        setupBindings()
        activate(tabIndex: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        observeEasyAccess()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        cancellablesForUser = []
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tabBar)
        view.addSubview(contentContainer)
        view.addSubview(easyAccessView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tabBar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 44),

            contentContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: easyAccessView.topAnchor),

            easyAccessView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            easyAccessView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            easyAccessView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        easyAccessCollapsedHeightConstraint.isActive = true
    }

    private func setupBindings() {
        WeDoBooksFacade.shared
            .events
            .bookInfoTapped
            .sink { isbn in
                print("Book info tapped for \(isbn)")
            }
            .store(in: &cancellables)

        WeDoBooksFacade.shared
            .events
            .finishBookTapped
            .sink { isbn in
                print("Finish book tapped for \(isbn)")
            }
            .store(in: &cancellables)

        WeDoBooksFacade.shared
            .events
            .bookWillClose
            .sink { [weak self] in
                self?.checkoutsViewController.reenableActions()
                print("Book will close")
            }
            .store(in: &cancellables)
    }

    private func observeEasyAccess() {
        do {
            try WeDoBooksFacade.shared
                .easyAccess
                .lastOpenedBook()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] data in
                    guard let self else { return }

                    if let data {
                        setEasyAccessVisible(true)
                        easyAccessView.configure(data: data)
                    } else {
                        setEasyAccessVisible(false)
                    }
                })
                .store(in: &cancellablesForUser)
        } catch {
            print("easyAccess.lastOpenedBook failed: \(error)")
        }
    }

    private func setEasyAccessVisible(_ isVisible: Bool) {
        easyAccessView.isHidden = !isVisible
        easyAccessCollapsedHeightConstraint.isActive = !isVisible
    }

    // MARK: - Tab switching

    private func activate(tabIndex: Int) {
        let controllers = orderedTabControllers
        guard controllers.indices.contains(tabIndex) else { return }

        let outgoing = controllers[activeTabIndex]
        if outgoing.parent === self {
            outgoing.willMove(toParent: nil)
            outgoing.view.removeFromSuperview()
            outgoing.removeFromParent()
        }

        activeTabIndex = tabIndex
        tabBar.setSelectedIndex(tabIndex, animated: true)

        let incoming = controllers[tabIndex]
        addChild(incoming)
        incoming.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(incoming.view)
        NSLayoutConstraint.activate([
            incoming.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            incoming.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            incoming.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            incoming.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
        incoming.didMove(toParent: self)
    }
}

// MARK: - EasyAccessViewDelegate

extension RootTabViewController: EasyAccessViewDelegate {
    func closeTapped() {
        setEasyAccessVisible(false)
        WeDoBooksFacade.shared
            .bookOperations
            .stopAudioPlayer()
    }

    func didActivate(checkout: Checkout) {
        Task { @MainActor in
            do {
                try await WeDoBooksFacade.shared
                    .bookOperations
                    .openCheckout(checkout, presentedBy: self)
            } catch {
                print("openCheckout from EasyAccess failed: \(error)")
            }
        }
    }
}

// MARK: - SettingsViewControllerDelegate

extension RootTabViewController: SettingsViewControllerDelegate {
    func settingsDidRequestLogout() {
        cancellablesForUser = []
        WeDoBooksFacade.shared.userOperations.signOut()
        delegate?.userDidLogout()
    }
}
