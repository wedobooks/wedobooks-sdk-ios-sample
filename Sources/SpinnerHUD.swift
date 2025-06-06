//
//  SpinnerHUD.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 06/06/2025.
//

import UIKit

class SpinnerHUD {
    private static var spinnerView: UIView?

    static func show(in view: UIView) {
        guard spinnerView == nil else { return }

        let spinnerView = UIView(frame: view.bounds)
        spinnerView.backgroundColor = UIColor(white: 0, alpha: 0.4)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = spinnerView.center
        spinner.startAnimating()

        spinnerView.addSubview(spinner)
        view.addSubview(spinnerView)

        self.spinnerView = spinnerView
    }

    static func hide() {
        spinnerView?.removeFromSuperview()
        spinnerView = nil
    }
}
