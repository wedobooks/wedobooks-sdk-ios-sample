//
//  LoginViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
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
    }
    
    // MARK: Private functions
    
    private func setupViewHierarchy() {
        view.addSubview(signInButton)
        
        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 200),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupControlActions() {
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
    }
    
    @objc
    private func signInButtonTapped(_ button: UIButton) {
        signInButton.isEnabled = false
        
        SpinnerHUD.show(in: view)
        
        Task {
            guard let token = try? await obtainDemoUserTokenAndSignIn() else {
                return
            }
            
            let signInResult = await WeDoBooksFacade.shared.userOperations.signIn(with: token)
            switch signInResult {
            case .success(let user):
                delegate?.userDidLogin()
                SpinnerHUD.hide()
                print("Sign in success: \(user)")
            case .failure(let error):
                print("Failure: \(error)")
            }
        }
    }
    
    private func obtainDemoUserTokenAndSignIn() async throws -> String? {
        guard let encodedURL = Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as? String,
              let url = encodedURL.removingPercentEncoding,
              let userId = Bundle.main.infoDictionary?["USER_ID"] as? String else {
            return nil
        }
        
        var request = URLRequest(url: URL(string: url)!)
        
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
