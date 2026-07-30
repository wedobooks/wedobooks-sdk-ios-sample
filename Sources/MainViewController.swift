//
//  ViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 21/03/2025.
//  Copyright © 2025 WeDoBooks A/S. All rights reserved.
//

import Combine
import FirebaseProvider
import UIKit
import WeDoBooksSDK

class MainViewController: UIViewController {
    private var navController = OrientationNavController()
    private var loginViewController = LoginViewController()
    private var rootTabViewController = RootTabViewController()

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
        rootTabViewController.delegate = self

        if WeDoBooksFacade.shared.userOperations.currentUserId != nil {
            navController.viewControllers = [rootTabViewController]
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

        let sdkGoogleInfoFileName = currentEnv.firebaseFile
        guard let sdkGoogleInfoFilePath = Bundle.main.path(
            forResource: sdkGoogleInfoFileName,
            ofType: nil
        ) else {
            fatalError("Path in bundle for SDK Google Info plist file not found")
        }

        try! WeDoBooksFacade.shared.setup(
            readerKey: readerKey,
            readerSecret: readerSecret,
            mode: currentEnv.mode,
            firebaseAdapterFactory: FirebaseAdapterFactory(),
            customProgressConfig: CustomProgressConfig(
                reader: SampleProgressConfig.customReaderProgress,
                player: SampleProgressConfig.customPlayerProgress
            ),
            firebaseConfigFilePath: sdkGoogleInfoFilePath
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
        navController.setViewControllers([rootTabViewController], animated: true)
    }
}

extension MainViewController: RootTabViewControllerDelegate {
    func userDidLogout() {
        navController.setViewControllers([loginViewController], animated: true)
    }
}
