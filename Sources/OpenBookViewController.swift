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
    
    private let logoutButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Logout"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    var wdb: WeDoBooksFacade?
    weak var delegate: OpenBookViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        openAudioBookButton.addTarget(self, action: #selector(audioBookButtonTapped), for: .touchUpInside)
        openEBookButton.addTarget(self, action: #selector(ebookButtonTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        themeSwitcher.addTarget(self, action: #selector(themeSwitcherInput), for: .valueChanged)
        
        setupViewHierarchy()
        
        wdb?.events
            .bookWillClose
            .sink { [weak self] _ in
                self?.openAudioBookButton.isEnabled = true
                self?.openEBookButton.isEnabled = true
                self?.logoutButton.isEnabled = true
            }
            .store(in: &cancellables)
    }
    
    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(openAudioBookButton)
        view.addSubview(openEBookButton)
        view.addSubview(themeSwitcher)
        view.addSubview(logoutButton)
        
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
            themeSwitcher.widthAnchor.constraint(equalTo: openEBookButton.widthAnchor),
            themeSwitcher.heightAnchor.constraint(equalTo: openEBookButton.heightAnchor),
            themeSwitcher.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: themeSwitcher.bottomAnchor, constant: 40),
            logoutButton.widthAnchor.constraint(equalTo: themeSwitcher.widthAnchor),
            logoutButton.heightAnchor.constraint(equalTo: themeSwitcher.heightAnchor),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func audioBookButtonTapped(_ button: UIButton) {
        openBook(isbn: "9780297395461")
    }
    
    @objc private func ebookButtonTapped(_ button: UIButton) {
        openBook(isbn: "9780994135094")
    }
    
    @objc private func logoutButtonTapped(_ button: UIButton) {
        print("Logout tapped")
        
        wdb?.userOperations.signUserOut()
        delegate?.didLogout()
    }
    
    @objc private func themeSwitcherInput() {
        if themeSwitcher.selectedSegmentIndex == 0 {
            wdb?.styling.lightTheme = nil
            wdb?.styling.darkTheme = nil
        } else {
            wdb?.styling.lightTheme = customLightTheme
            wdb?.styling.darkTheme = customDarkTheme
        }
    }
    
    private func openBook(isbn: String) {
        openAudioBookButton.isEnabled = false
        openEBookButton.isEnabled = false
        logoutButton.isEnabled = false
        
        Task { @MainActor in
            let checkoutResult = await wdb?.bookOperations.checkoutBook(with: isbn)
            switch checkoutResult {
            case .success(let checkout):
                do {
                    try wdb?.bookOperations.openCheckout(checkout, presentedBy: self)
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
