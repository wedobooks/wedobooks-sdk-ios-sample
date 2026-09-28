//
//  LoginViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
//  Copyright © 2025 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

protocol LoginViewControllerDelegate: AnyObject {
    func userDidLogin()
}

final class LoginViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []

    private let signInButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Sign in"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    // Pull-down of the ids that have signed in on this environment before. Hidden while empty.
    private let savedUsersButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Saved users"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.showsMenuAsPrimaryAction = true
        return result
    }()

    private lazy var environmentPicker: EnvironmentPickerView = {
        let result = EnvironmentPickerView(environments: EnvironmentCatalog.all, selected: currentEnv)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.onTap = { [weak self] in
            self?.openEnvironmentList()
        }
        return result
    }()
    private var userIdField: UITextField = {
            let result = UITextField()
            let placeholder = NSAttributedString(
                string: "User id",
                attributes: [.foregroundColor: UIColor.lightGray]
            )
            result.attributedPlaceholder = placeholder
            result.borderStyle = .roundedRect
            result.translatesAutoresizingMaskIntoConstraints = false
            return result
        }()

    private var token: String?
    
    weak var delegate: LoginViewControllerDelegate?
    
    // MARK: Override vars
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }
    
    // MARK: View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupViewHierarchy()
        setupControlActions()
        refreshSavedUsersMenu()
    }
    
    // MARK: Private functions
    
    private func setupViewHierarchy() {
        // A stack, so the saved-users button takes no space while it's hidden.
        let formStack = UIStackView(arrangedSubviews: [userIdField, signInButton, savedUsersButton])
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.axis = .vertical
        formStack.spacing = 8

        view.addSubview(formStack)
        view.addSubview(environmentPicker)

        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            formStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            formStack.widthAnchor.constraint(equalToConstant: 200),

            userIdField.heightAnchor.constraint(equalToConstant: 50),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
            savedUsersButton.heightAnchor.constraint(equalToConstant: 50),

            environmentPicker.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 40),
            environmentPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            environmentPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func refreshSavedUsersMenu() {
        let userIds = SavedValues.userIds.all()
        savedUsersButton.isHidden = userIds.isEmpty
        guard !userIds.isEmpty else {
            savedUsersButton.menu = nil
            return
        }

        let picks = userIds.map { userId in
            UIAction(title: userId, state: userId == enteredUserId ? .on : .off) { [weak self] _ in
                self?.userIdField.text = userId
                self?.refreshSavedUsersMenu()
            }
        }
        let removals = userIds.map { userId in
            UIAction(title: userId, attributes: .destructive) { [weak self] _ in
                SavedValues.userIds.remove(userId)
                self?.refreshSavedUsersMenu()
            }
        }
        savedUsersButton.menu = UIMenu(children: [
            UIMenu(options: .displayInline, children: picks),
            UIMenu(title: "Remove", image: UIImage(systemName: "trash"), children: removals),
        ])
    }

    private var enteredUserId: String {
        (userIdField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func setupControlActions() {
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
    }
    
    @objc
    private func signInButtonTapped(_ button: UIButton) {
        signInButton.isEnabled = false
        let userId = enteredUserId
        
        SpinnerHUD.show(in: view)
        
        Task {
            // The HUD covers the whole screen — including the environment picker, which is what
            // a failed sign-in most often calls for — so it has to come down on every exit.
            defer {
                SpinnerHUD.hide()
                signInButton.isEnabled = true
            }

            guard let token = try? await obtainDemoUserTokenAndSignIn(userId: userId) else {
                return
            }

            let signInResult = await WeDoBooksFacade.shared.userOperations.signIn(with: token)
            switch signInResult {
            case .success(let user):
                SavedValues.userIds.save(userId)
                refreshSavedUsersMenu()
                delegate?.userDidLogin()
                print("Sign in success: \(user)")
            case .failure(let error):
                print("Failure: \(error)")
            }
        }
    }
    
    private func openEnvironmentList() {
        let listVC = EnvironmentSheetViewController(environments: EnvironmentCatalog.all, selected: currentEnv)
        listVC.onPick = { [weak self] environment in
            self?.confirmSwitch(to: environment)
        }
        present(listVC, animated: true)
    }

    /// The SDK (and the Firebase app behind it) is configured once per launch in
    /// `MainViewController`, so another environment can only be picked up by a fresh process.
    private func confirmSwitch(to environment: Environment) {
        guard environment.id != currentEnv.id else { return }

        // Setup runs before this screen exists, so an environment whose Firebase file is missing
        // from the bundle would crash on every launch instead of coming back here. Refuse it now.
        guard Bundle.main.path(forResource: environment.firebaseFile, ofType: nil) != nil else {
            let alert = UIAlertController(
                title: "\(environment.displayName) is not set up",
                message: "\(environment.firebaseFile) isn't in the app bundle. Add it to the app target (see Environments.swift in the README) and build again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: "Switch to \(environment.displayName)?",
            message: "The app closes now so it can configure the SDK for \(environment.displayName), and posts a notification you can tap to reopen it.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Switch and restart", style: .default) { _ in
            EnvironmentCatalog.select(environment)
            // iOS gives an app no way to relaunch itself, so the closest thing is a notification
            // to tap. Fine for a sample app — a shipping app should never call `exit`.
            AppRestarter.closeAndOfferRelaunch(
                title: "Ready to run against \(environment.displayName)",
                body: "Tap to reopen the sample app."
            )
        })

        present(alert, animated: true)
    }

    private func obtainDemoUserTokenAndSignIn(userId: String) async throws -> String? {
        var request = URLRequest(url: URL(string: currentEnv.tokenUrl)!)
        
        let body = try! JSONSerialization.data(withJSONObject: ["uid": userId], options: [])
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = body
        
        do {
            let config = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: config)
            let (data, _) = try await session.data(for: request)
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
            let customToken = json?["token"] as? String
            print("Received token: \(customToken ?? "<nil>")")
            return customToken
        } catch {
            print("Request failed with error: \(error)")
            throw error
        }
    }
}
