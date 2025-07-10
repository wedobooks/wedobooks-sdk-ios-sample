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
    private var cancellables: Set<AnyCancellable> = []
    private var cancellablesForUser: Set<AnyCancellable> = []
    
    private let openAudioBookButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Open audiobook"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let openEBookButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Open ebook"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let statsButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Stats"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let themeSwitcher: UISegmentedControl = {
        let result = UISegmentedControl(items: ["Default", "Custom"])
        result.translatesAutoresizingMaskIntoConstraints = false
        result.selectedSegmentIndex = 0
        return result
    }()
    
    private let stopAudioButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Stop audio"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isEnabled = true
        return result
    }()
    
    private let logoutButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Logout"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isEnabled = true
        return result
    }()
    
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
        view.addSubview(logoutButton)
        view.addSubview(easyAccessView)
        view.addSubview(statsButton)
        
        NSLayoutConstraint.activate([
            openAudioBookButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            openAudioBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openAudioBookButton.widthAnchor.constraint(equalToConstant: 200),
            openAudioBookButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            openEBookButton.topAnchor.constraint(equalTo: openAudioBookButton.bottomAnchor, constant: 40),
            openEBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openEBookButton.widthAnchor.constraint(equalToConstant: 200),
            openEBookButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            statsButton.topAnchor.constraint(equalTo: openEBookButton.bottomAnchor, constant: 40),
            statsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsButton.widthAnchor.constraint(equalToConstant: 200),
            statsButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            themeSwitcher.topAnchor.constraint(equalTo: statsButton.bottomAnchor, constant: 40),
            themeSwitcher.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            themeSwitcher.widthAnchor.constraint(equalToConstant: 200),
            themeSwitcher.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            stopAudioButton.topAnchor.constraint(equalTo: themeSwitcher.bottomAnchor, constant: 40),
            stopAudioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopAudioButton.widthAnchor.constraint(equalToConstant: 200),
            stopAudioButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: stopAudioButton.bottomAnchor, constant: 40),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 200),
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
            // Ask us for isbn to use
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
            // Ask us for isbn to use
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
