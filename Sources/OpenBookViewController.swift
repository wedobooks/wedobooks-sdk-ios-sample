//
//  OpenBookViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
//

import Combine
import UIKit
import WeDoBooksSDK

protocol OpenBookViewControllerDelegate: AnyObject {
    func userDidLogout()
}

final class OpenBookViewController: UIViewController {
    private let buttonWidth: CGFloat = 240
    private let controlVerticalSpacing: CGFloat = 24

    private var cancellables: Set<AnyCancellable> = []
    private var cancellablesForUser: Set<AnyCancellable> = []

    private let scrollView: UIScrollView = {
        let result = UIScrollView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.alwaysBounceVertical = true
        return result
    }()

    private let controlsContentView: UIView = {
        let result = UIView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let controlsStackView: UIStackView = {
        let result = UIStackView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.axis = .vertical
        result.alignment = .center
        result.spacing = 24
        return result
    }()

    private let openAudioBookButton = UIButton(title: "Open audiobook")

    private let openEBookButton = UIButton(title: "Open ebook")

    private let headlessButton = UIButton(title: "Headless audiobook")

    private let statsButton = UIButton(title: "Stats")

    private let themeSwitcher: UISegmentedControl = {
        let result = UISegmentedControl(items: ["Default theme", "Custom theme"])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.selectedSegmentIndex = 0
        return result
    }()

    private let stopAudioButton = UIButton(title: "Stop audio")

    private let downloadedBooksButton = UIButton(title: "Downloaded books")

    private let logoutButton = UIButton(title: "Logout")

    private let easyAccessView: EasyAccessView = {
        let result = EasyAccessView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private lazy var easyAccessCollapsedHeightConstraint: NSLayoutConstraint =
        easyAccessView.heightAnchor.constraint(equalToConstant: 0)

    weak var delegate: OpenBookViewControllerDelegate?

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupViewHierarchy()
        setupControlActions()
        setupBindings()

        easyAccessView.delegate = self
        setEasyAccessVisible(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observeEasyAccess()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        cancellablesForUser = []
    }

    // MARK: Override vars

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    // MARK: Private functions

    private func setupViewHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(controlsContentView)
        controlsContentView.addSubview(controlsStackView)

        view.addSubview(easyAccessView)

        [
            openAudioBookButton,
            openEBookButton,
            headlessButton,
            statsButton,
            themeSwitcher,
            stopAudioButton,
            downloadedBooksButton,
            logoutButton,
        ].forEach(controlsStackView.addArrangedSubview)

        [
            openAudioBookButton,
            openEBookButton,
            headlessButton,
            statsButton,
            stopAudioButton,
            downloadedBooksButton,
            logoutButton,
        ].forEach(applyControlDimensions)

        NSLayoutConstraint.activate([
            themeSwitcher.widthAnchor.constraint(equalToConstant: buttonWidth),
            themeSwitcher.heightAnchor.constraint(equalToConstant: 50),
        ])

        controlsStackView.spacing = controlVerticalSpacing

        NSLayoutConstraint.activate([
            easyAccessView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            easyAccessView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            easyAccessView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        easyAccessCollapsedHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: easyAccessView.topAnchor, constant: -12),
        ])

        NSLayoutConstraint.activate([
            controlsContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            controlsContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            controlsContentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            controlsContentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            controlsContentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        NSLayoutConstraint.activate([
            controlsStackView.topAnchor.constraint(equalTo: controlsContentView.topAnchor, constant: 20),
            controlsStackView.centerXAnchor.constraint(equalTo: controlsContentView.centerXAnchor),
            controlsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: controlsContentView.leadingAnchor, constant: 20),
            controlsStackView.trailingAnchor.constraint(lessThanOrEqualTo: controlsContentView.trailingAnchor, constant: -20),
            controlsStackView.bottomAnchor.constraint(equalTo: controlsContentView.bottomAnchor, constant: -20),
        ])

        scrollView.contentInset.bottom = 20
        scrollView.verticalScrollIndicatorInsets.bottom = 20
    }

    private func applyControlDimensions(_ view: UIView) {
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: buttonWidth),
            view.heightAnchor.constraint(equalToConstant: 50),
        ])
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
                self?.openEBookButton.isEnabled = true
                self?.openAudioBookButton.isEnabled = true
                print("Book will close")
            }
            .store(in: &cancellables)
    }

    private func setupControlActions() {
        openAudioBookButton.addTarget(self, action: #selector(openAudiobookButtonTapped), for: .touchUpInside)
        openEBookButton.addTarget(self, action: #selector(openEbookButtonTapped), for: .touchUpInside)
        headlessButton.addTarget(self, action: #selector(headlessButtonTapped), for: .touchUpInside)
        themeSwitcher.addTarget(self, action: #selector(themeSwitcherInput), for: .valueChanged)
        stopAudioButton.addTarget(self, action: #selector(stopAudioButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        statsButton.addTarget(self, action: #selector(statsButtonTapped), for: .touchUpInside)
        downloadedBooksButton.addTarget(self, action: #selector(downloadedBooksButtonTapped), for: .touchUpInside)
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

    @objc
    private func openAudiobookButtonTapped() {
        openAudioBookButton.isEnabled = false
        Task { @MainActor in
            let isbn = currentEnv.audioBookIsbn
            let checkoutResult = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: isbn)
            switch checkoutResult {
            case .success(let checkout):
                let url = URL(string: "https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1394988109i/22034.jpg")!
                // Comment below for easy changing between custom url and custom image for testing
//                let image = UIImage(named: "CustomCover")!
                do {
                    try WeDoBooksFacade.shared
                        .bookOperations
                        .openCheckout(
                            checkout,
                            presentedBy: self,
                            customCover: .url(url)
//                          customCover: .image(image)
                        )
                } catch {
                    print("openCheckout from Open audiobook failed: \(error)")
                    openAudioBookButton.isEnabled = true
                }
            case .failure(let error):
                print("checkout audiobook failed: \(error)")
                openAudioBookButton.isEnabled = true
            }
        }
    }

    @objc
    private func openEbookButtonTapped() {
        openEBookButton.isEnabled = false

        Task { @MainActor in
            
            let isbn = currentEnv.ebookIsbn
            let checkoutResult = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: isbn)
            switch checkoutResult {
            case .success(let checkout):
                do {
                    try WeDoBooksFacade.shared.bookOperations.openCheckout(checkout, presentedBy: self)
                } catch {
                    print("openCheckout from Open ebook failed: \(error)")
                    openEBookButton.isEnabled = true
                }
            case .failure(let error):
                print("checkout ebook failed: \(error)")
                openEBookButton.isEnabled = true
            }
        }
    }

    @objc
    private func headlessButtonTapped() {
        let vc = HeadlessAudiobookViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    private func themeSwitcherInput() {
        if themeSwitcher.selectedSegmentIndex == 0 {
            WeDoBooksFacade.shared.styling.lightTheme = nil
            WeDoBooksFacade.shared.styling.darkTheme = nil
        } else {
            WeDoBooksFacade.shared.styling.lightTheme = customLightTheme
            WeDoBooksFacade.shared.styling.darkTheme = customDarkTheme
        }
    }

    @objc
    private func stopAudioButtonTapped() {
        WeDoBooksFacade.shared.bookOperations.stopAudioPlayer()
    }

    @objc
    private func logoutButtonTapped() {
        cancellablesForUser = []
        WeDoBooksFacade.shared.userOperations.signOut()
        delegate?.userDidLogout()
    }

    @objc
    private func statsButtonTapped() {
        let vc = StatsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    private func downloadedBooksButtonTapped() {
        let vc = DownloadedBooksViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension OpenBookViewController: EasyAccessViewDelegate {
    func closeTapped() {
        setEasyAccessVisible(false)
        WeDoBooksFacade.shared
            .bookOperations
            .stopAudioPlayer()
    }

    func didActivate(checkout: Checkout) {
        do {
            try WeDoBooksFacade.shared
                .bookOperations
                .openCheckout(checkout, presentedBy: self)
        } catch {
            print("openCheckout from EasyAccess failed: \(error)")
        }
    }
}
