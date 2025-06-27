//
//  LoginViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
//

import UIKit
import WeDoBooksSDK

protocol LoginViewControllerDelegate: AnyObject {
    func didLogin()
}

class LoginViewController: UIViewController {
    private let titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.font = .systemFont(ofSize: 24, weight: .bold)
        result.text = "Login"
        result.textColor = .label
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    private let uidTextField: UITextField = {
        let result = UITextField()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.borderStyle = .none
        result.backgroundColor = .secondarySystemBackground
        result.textColor = .label
        result.tintColor = .systemBlue  // cursor/caret color
        result.layer.borderWidth = 1
        result.layer.borderColor = UIColor.separator.cgColor
        result.layer.masksToBounds = true
        result.placeholder = "User ID"
        result.clearButtonMode = .always
        result.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        result.leftViewMode = .always
        return result
    }()
    
    private let loginButton: UIButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Login"))
        result.translatesAutoresizingMaskIntoConstraints = false
        result.isEnabled = false
        return result
    }()
    
    var wdb: WeDoBooksFacade?
    weak var delegate: LoginViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        uidTextField.delegate = self
        uidTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        if let userId = Bundle.main.infoDictionary?["USER_ID"] as? String {
            uidTextField.text = userId
            loginButton.isEnabled = true
        }
        
        setupViewHierarchy()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        uidTextField.becomeFirstResponder()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        uidTextField.layer.borderColor = UIColor.separator.cgColor
    }
    
    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(uidTextField)
        view.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate([
            uidTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            uidTextField.widthAnchor.constraint(equalToConstant: 300),
            uidTextField.heightAnchor.constraint(equalToConstant: 44),
            uidTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: uidTextField.bottomAnchor, constant: 40),
            loginButton.widthAnchor.constraint(equalTo: uidTextField.widthAnchor),
            loginButton.heightAnchor.constraint(equalTo: uidTextField.heightAnchor),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        loginButton.isEnabled = !(textField.text?.isEmpty ?? true)
    }
    
    @objc private func loginButtonTapped(_ button: UIButton) {
        uidTextField.resignFirstResponder()
        
        loginButton.isEnabled = false
        uidTextField.isEnabled = false
        
        SpinnerHUD.show(in: view)
        
        Task {
            guard let token = try? await obtainDemoUserTokenAndSignIn() else {
                return
            }
            
            let signInResult = await wdb?.userOperations.signIn(with: token)
            switch signInResult {
            case .none:
                print("None")
            case .success:
                delegate?.didLogin()
                SpinnerHUD.hide()
            case .failure:
                print("Failure")
            }
        }
    }
    
    private func obtainDemoUserTokenAndSignIn() async throws -> String? {
        guard let url = Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as? String else {
            return nil
        }
        let uid = uidTextField.text ?? ""
        var request = URLRequest(url: URL(string: url)!)
        
        let body = try! JSONSerialization.data(withJSONObject: ["uid": uid], options: [])
        
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

extension LoginViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let currentText = textField.text, let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            loginButton.isEnabled = !updatedText.isEmpty
        }
        return true
    }
}
