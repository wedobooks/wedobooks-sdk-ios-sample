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
    private let controleVerticalSpace: CGFloat = 30
    
    private var cancellables: Set<AnyCancellable> = []
    private var cancellablesForUser: Set<AnyCancellable> = []
    
    private let openAudioBookButton = UIButton(title: "Open audiobook")
    
    private let openEBookButton = UIButton(title: "Open ebook")
    
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
    
    weak var delegate: OpenBookViewControllerDelegate?
    
    // MARK: View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupViewHierarchy()
        setupControlActions()
        setupBindings()
        
        easyAccessView.isHidden = true
        easyAccessView.delegate = self
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
        view.addSubview(openAudioBookButton)
        view.addSubview(openEBookButton)
        view.addSubview(themeSwitcher)
        view.addSubview(stopAudioButton)
        view.addSubview(downloadedBooksButton)
        view.addSubview(logoutButton)
        view.addSubview(easyAccessView)
        view.addSubview(statsButton)
        
        NSLayoutConstraint.activate([
            openAudioBookButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            openAudioBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openAudioBookButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            openAudioBookButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            openEBookButton.topAnchor.constraint(equalTo: openAudioBookButton.bottomAnchor, constant: controleVerticalSpace),
            openEBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openEBookButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            openEBookButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            statsButton.topAnchor.constraint(equalTo: openEBookButton.bottomAnchor, constant: controleVerticalSpace),
            statsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            statsButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            themeSwitcher.topAnchor.constraint(equalTo: statsButton.bottomAnchor, constant: controleVerticalSpace),
            themeSwitcher.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            themeSwitcher.widthAnchor.constraint(equalToConstant: buttonWidth),
            themeSwitcher.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            stopAudioButton.topAnchor.constraint(equalTo: themeSwitcher.bottomAnchor, constant: controleVerticalSpace),
            stopAudioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopAudioButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            stopAudioButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            downloadedBooksButton.topAnchor.constraint(equalTo: stopAudioButton.bottomAnchor, constant: controleVerticalSpace),
            downloadedBooksButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadedBooksButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            downloadedBooksButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: downloadedBooksButton.bottomAnchor, constant: controleVerticalSpace),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            easyAccessView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            easyAccessView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            easyAccessView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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
        
//        wdb?.events
//            .finishBookTapped
//            .sink { isbn in
//                print("Finish book tapped for \(isbn)")
//            }
//            .store(in: &cancellables)
        
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
        themeSwitcher.addTarget(self, action: #selector(themeSwitcherInput), for: .valueChanged)
        stopAudioButton.addTarget(self, action: #selector(stopAudioButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        statsButton.addTarget(self, action: #selector(statsButtonTapped), for: .touchUpInside)
        downloadedBooksButton.addTarget(self, action: #selector(downloadedBooksButtonTapped), for: .touchUpInside)
    }
    
    private func observeEasyAccess() {
        try! WeDoBooksFacade.shared
            .easyAccess
            .lastOpenedBook()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] data in
                guard let self else { return }
                
                if let data {
                    easyAccessView.isHidden = false
                    easyAccessView.configure(data: data)
                } else {
                    easyAccessView.isHidden = true
                }
            })
            .store(in: &cancellablesForUser)
    }
    
    @objc
    private func openAudiobookButtonTapped() {
        openAudioBookButton.isEnabled = false
        Task {
            let checkoutResult = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: "9788702073416")
            switch checkoutResult {
            case .success(let checkout):
                do {
                    try WeDoBooksFacade.shared.bookOperations.openCheckout(checkout, presentedBy: self)//, customCoverImage: UIImage(named: "CustomCover"))
                } catch {
                    print("open checkout failed: \(error)")
                    openAudioBookButton.isEnabled = true
                }
            case .failure(let error):
                print("Checkout audio book failed: \(error)")
                openAudioBookButton.isEnabled = true
            }
        }
    }
    
    @objc
    private func openEbookButtonTapped() {
        openEBookButton.isEnabled = false
        
        Task { @MainActor in
            let checkoutResult = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: "9788702437782")
            switch checkoutResult {
            case .success(let checkout):
                do {
                    try WeDoBooksFacade.shared.bookOperations.openCheckout(checkout, presentedBy: self)//, customCoverImage: UIImage(named: "CustomCover"))
                } catch {
                    print("open checkout failed: \(error)")
                    openEBookButton.isEnabled = true
                }
            case .failure(let error):
                print("Checkout ebook failed: \(error)")
                openEBookButton.isEnabled = true
            }
        }
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
        easyAccessView.isHidden = true
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
            print("Open checkout failed: \(error)")
        }
    }
}
