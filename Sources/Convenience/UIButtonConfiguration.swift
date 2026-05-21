//
//  UIButtonConfiguration.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 16/06/2025.
//  Copyright © 2025 WeDoBooks A/S. All rights reserved.
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
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = Theme.buttonFill
        config.baseForegroundColor = Theme.buttonText
        config.cornerStyle = .fixed
        config.background.cornerRadius = Theme.buttonCornerRadius
        return config
    }
}
