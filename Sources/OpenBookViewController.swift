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
    func didLogout()
}

class OpenBookViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []
    
    private let titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.font = .systemFont(ofSize: 24, weight: .bold)
        result.text = "Open book"
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let openAudioBookButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Audio book"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let openEBookButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Ebook"))
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
        return result
    }()
    
    private let easyAccessView: EasyAccessView = {
        let result = EasyAccessView()
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    weak var delegate: OpenBookViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        easyAccessView.isHidden = true
        easyAccessView.delegate = self
        
        openAudioBookButton.addTarget(self, action: #selector(audioBookButtonTapped), for: .touchUpInside)
        openEBookButton.addTarget(self, action: #selector(ebookButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        themeSwitcher.addTarget(self, action: #selector(themeSwitcherInput), for: .valueChanged)
        stopAudioButton.addTarget(self, action: #selector(stopAudioButtonTapped), for: .touchUpInside)
        
        setupViewHierarchy()
        
        WeDoBooksFacade.shared
            .events
            .bookWillClose
            .sink { [weak self] _ in
                self?.openAudioBookButton.isEnabled = true
                self?.openEBookButton.isEnabled = true
                self?.logoutButton.isEnabled = true
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        observeEasyAccess()
    }
    
    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(openAudioBookButton)
        view.addSubview(openEBookButton)
        view.addSubview(themeSwitcher)
        view.addSubview(stopAudioButton)
        view.addSubview(logoutButton)
        view.addSubview(easyAccessView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate([
            openAudioBookButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            openAudioBookButton.widthAnchor.constraint(equalToConstant: 300),
            openAudioBookButton.heightAnchor.constraint(equalToConstant: 44),
            openAudioBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            openEBookButton.topAnchor.constraint(equalTo: openAudioBookButton.bottomAnchor, constant: 40),
            openEBookButton.widthAnchor.constraint(equalTo: openAudioBookButton.widthAnchor),
            openEBookButton.heightAnchor.constraint(equalTo: openAudioBookButton.heightAnchor),
            openEBookButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            themeSwitcher.topAnchor.constraint(equalTo: openEBookButton.bottomAnchor, constant: 40),
            themeSwitcher.widthAnchor.constraint(equalTo: openAudioBookButton.widthAnchor),
            themeSwitcher.heightAnchor.constraint(equalTo: openAudioBookButton.heightAnchor),
            themeSwitcher.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stopAudioButton.topAnchor.constraint(equalTo: themeSwitcher.bottomAnchor, constant: 40),
            stopAudioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopAudioButton.widthAnchor.constraint(equalTo: openAudioBookButton.widthAnchor),
            stopAudioButton.heightAnchor.constraint(equalTo: openAudioBookButton.heightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: stopAudioButton.bottomAnchor, constant: 40),
            logoutButton.widthAnchor.constraint(equalTo: openAudioBookButton.widthAnchor),
            logoutButton.heightAnchor.constraint(equalTo: openAudioBookButton.heightAnchor),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            easyAccessView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            easyAccessView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            easyAccessView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
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
            .store(in: &cancellables)
    }
    
    @objc private func audioBookButtonTapped(_ button: UIButton) {
        // Ask us for isbn to use
        openBook(isbn: "9788702073416")
    }
    
    @objc private func ebookButtonTapped(_ button: UIButton) {
        // Ask us for isbn to use
        openBook(isbn: "9788702437782")
    }
    
    @objc private func logoutButtonTapped(_ button: UIButton) {
        WeDoBooksFacade.shared.userOperations.signOut()
        delegate?.didLogout()
    }
    
    @objc private func themeSwitcherInput() {
        if themeSwitcher.selectedSegmentIndex == 0 {
            WeDoBooksFacade.shared.styling.lightTheme = nil
            WeDoBooksFacade.shared.styling.darkTheme = nil
        } else {
            WeDoBooksFacade.shared.styling.lightTheme = customLightTheme
            WeDoBooksFacade.shared.styling.darkTheme = customDarkTheme
        }
    }
    
    @objc private func stopAudioButtonTapped() {
        WeDoBooksFacade.shared.bookOperations.stopAudioPlayer()
    }
    
    private func openBook(isbn: String) {
        openAudioBookButton.isEnabled = false
        openEBookButton.isEnabled = false
        logoutButton.isEnabled = false
        
        Task { @MainActor in
            let checkoutResult = await WeDoBooksFacade.shared.bookOperations.checkoutBook(with: isbn)
            switch checkoutResult {
            case .success(let checkout):
                do {
                    try WeDoBooksFacade.shared.bookOperations.openCheckout(checkout, presentedBy: self)
                } catch {
                    print("open checkout failed: \(error)")
                    openAudioBookButton.isEnabled = true
                    openEBookButton.isEnabled = true
                    logoutButton.isEnabled = true
                }
            case .failure(let error):
                print("Checkout book failed: \(error)")
                fallthrough
            default:
                openAudioBookButton.isEnabled = true
                openEBookButton.isEnabled = true
                logoutButton.isEnabled = true
            }
        }
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
