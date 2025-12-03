//
//  ViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 21/03/2025.
//

import Combine
import FirebaseProvider
import UIKit
import WeDoBooksSDK

class MainViewController: UIViewController {
    private var navController = OrientationNavController()
    private var loginViewController = LoginViewController()
    private var openBookViewController = OpenBookViewController()
    
    // MARK: Override vars
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }
    
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
                
        setupWDBFacade()
        
        navController.willMove(toParent: self)
        addChild(navController)
        view.addSubview(navController.view)
        navController.didMove(toParent: self)
        
        loginViewController.delegate = self
        openBookViewController.delegate = self
        
        if WeDoBooksFacade.shared.userOperations.currentUserId != nil {
            navController.viewControllers = [openBookViewController]
        } else {
            navController.viewControllers = [loginViewController]
        }
    }
    
    // MARK: Private functions
    
    private func setupWDBFacade() {
        guard let readerKey = Bundle.main.infoDictionary?["READER_KEY"] as? String,
           let readerSecret = Bundle.main.infoDictionary?["READER_SECRET"] as? String else {
            fatalError("Missing secrets for the reader")
        }
        
        try! WeDoBooksFacade.shared.setup(
            readerKey: readerKey,
            readerSecret: readerSecret,
            firebaseAdapterFactory: FirebaseAdapterFactory()
        )
        WeDoBooksFacade.shared.localization.setLanguage(.english)
        let localizations: [WeDoBooksFacade.Localization.LocalizationKeys : [WeDoBooksFacade.Localization.Language : String]] = [
            .buttonSave : [.english : "Custom save"],
            .playerPlaybackRateReset : [.english : "Custom reset"],
            .playerPlaybackRateSpeed : [.english : "Custom speed"],
            .playerMoreMenuAboutBookLabel : [.english : "Custom about book"],
        ]
        WeDoBooksFacade.shared.localization.setCustomLocalizations(localizations)
        
        WeDoBooksFacade.shared.configuration.showFinishEbookButton = false
        WeDoBooksFacade.shared.configuration.showFinishAudiobookButton = false
        WeDoBooksFacade.shared.configuration.showAboutAudioBookButton = false
        WeDoBooksFacade.shared.configuration.allowEbookDownloadUsingMobileData = true
        
        WeDoBooksFacade.shared.images.icons.set(.close, to: "sf:xmark.app")
        WeDoBooksFacade.shared.images.icons.set(.down, to: "down-alt")
    }
}

extension MainViewController: LoginViewControllerDelegate {
    func userDidLogin() {
        navController.setViewControllers([openBookViewController], animated: true)
    }
}

extension MainViewController: OpenBookViewControllerDelegate {
    func userDidLogout() {
        navController.setViewControllers([loginViewController], animated: true)
    }
}
