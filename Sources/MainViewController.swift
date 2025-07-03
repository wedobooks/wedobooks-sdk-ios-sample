//
//  ViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 21/03/2025.
//

import UIKit
import WeDoBooksSDK

class MainViewController: BaseViewController {
    private var wdb: WeDoBooksFacade?
    
    private var loginViewController: LoginViewController?
    private var openBookViewController: OpenBookViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWDBFacade()
        
        if wdb?.userOperations.currentUserId != nil {
            updateOpenBookViewControllerVisibility(true)
        } else {
            updateLoginViewControllerVisibility(true)
        }
    }

    private func setupWDBFacade() {
        guard let readerKey = Bundle.main.infoDictionary?["READER_KEY"] as? String,
           let readerSecret = Bundle.main.infoDictionary?["READER_SECRET"] as? String else {
            return
        }
        
        wdb = WeDoBooksFacade.shared
        try! wdb?.setup(
            readerKey: readerKey,
            readerSecret: readerSecret
        )
        wdb?.localization.setLanguage(.english)
    }
    
    private func updateLoginViewControllerVisibility(_ show: Bool) {
        if show {
            let vc = LoginViewController(nibName: nil, bundle: nil)
            vc.delegate = self
            vc.willMove(toParent: self)
            addChild(vc)
            view.addSubview(vc.view)
            vc.didMove(toParent: self)
            loginViewController = vc
        } else {
            loginViewController?.willMove(toParent: nil)
            loginViewController?.view.removeFromSuperview()
            loginViewController?.removeFromParent()
            loginViewController?.didMove(toParent: nil)
            loginViewController = nil
        }
    }
    
    private func updateOpenBookViewControllerVisibility(_ show: Bool) {
        if show {
            let vc = OpenBookViewController(nibName: nil, bundle: nil)
            vc.delegate = self
            vc.willMove(toParent: self)
            addChild(vc)
            view.addSubview(vc.view)
            vc.didMove(toParent: self)
            openBookViewController = vc
        } else {
            openBookViewController?.willMove(toParent: nil)
            openBookViewController?.view.removeFromSuperview()
            openBookViewController?.removeFromParent()
            openBookViewController?.didMove(toParent: nil)
            openBookViewController = nil
        }
    }
}

extension MainViewController: LoginViewControllerDelegate {
    func didLogin() {
        updateLoginViewControllerVisibility(false)
        updateOpenBookViewControllerVisibility(true)
    }
}

extension MainViewController: OpenBookViewControllerDelegate {
    func didLogout() {
        updateLoginViewControllerVisibility(true)
        updateOpenBookViewControllerVisibility(false)
    }
}
