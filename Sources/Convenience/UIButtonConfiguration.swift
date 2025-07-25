//
//  UIButtonConfiguration.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 16/06/2025.
//

import UIKit

extension UIButton {
    convenience init(title: String) {
        self.init(configuration: UIButton.Configuration.standardConfiguration(for: title))
        translatesAutoresizingMaskIntoConstraints = false
    }
}

extension UIButton.Configuration {
    static func standardConfiguration(for title: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.baseForegroundColor = .label
        config.cornerStyle = .fixed
        config.background.cornerRadius = 0
        return config
    }
}
