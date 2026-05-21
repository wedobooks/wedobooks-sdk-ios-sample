//
//  Theme.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

enum Theme {
    /// Selected tab indicator, selected tab text, current page dot.
    /// Dark maroon in light mode, near-white in dark mode (mirrors Material's onSurface treatment).
    static let primary = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.96, alpha: 1.0)
            : UIColor(red: 0.30, green: 0.10, blue: 0.09, alpha: 1.0)
    }

    /// Filled-button background. Dark maroon in light mode, light pink in dark mode.
    static let buttonFill = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.86, blue: 0.83, alpha: 1.0)
            : UIColor(red: 0.30, green: 0.10, blue: 0.09, alpha: 1.0)
    }

    /// Filled-button title color. Inverse of `buttonFill`.
    static let buttonText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.10, blue: 0.09, alpha: 1.0)
            : UIColor.white
    }

    /// Destructive button background — stays dark maroon in both modes for emphasis.
    static let destructiveFill = UIColor(red: 0.30, green: 0.10, blue: 0.09, alpha: 1.0)

    /// Destructive button text — stays white in both modes.
    static let destructiveText = UIColor.white

    /// Card surface background. Pure white in light mode, secondarySystemBackground in dark mode.
    static let cardBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : UIColor.white
    }

    static let cardCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 14

    /// Apply a card surface (rounded corners + subtle shadow) to the given view.
    /// Caller should ensure surrounding containers don't clip the view bounds.
    static func applyCardStyle(to view: UIView, cornerRadius: CGFloat = Theme.cardCornerRadius) {
        view.backgroundColor = Theme.cardBackground
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
