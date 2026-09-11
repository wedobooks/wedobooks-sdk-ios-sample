//
//  EnvironmentPickerView.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 07/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

final class EnvironmentPickerView: UIView {
    var onTap: (() -> Void)?

    private let selected: Environment

    private let captionLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "ENVIRONMENT"
        result.font = .systemFont(ofSize: 13, weight: .semibold)
        result.textColor = .secondaryLabel
        result.textAlignment = .center
        return result
    }()

    private let button: UIButton = {
        let result = UIButton(type: .system)
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()

    init(environments: [Environment], selected: Environment) {
        self.selected = selected

        super.init(frame: .zero)

        button.configuration = makeButtonConfiguration()
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.isEnabled = environments.count > 1

        setupViewHierarchy()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Private functions

    private func setupViewHierarchy() {
        addSubview(captionLabel)
        addSubview(button)

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            button.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
        ])
    }

    private func makeButtonConfiguration() -> UIButton.Configuration {
        var result = UIButton.Configuration.tinted()
        result.title = selected.displayName
        result.subtitle = selected.pickerSubtitle
        result.image = UIImage(systemName: "chevron.up.chevron.down")
        result.imagePlacement = .trailing
        result.imagePadding = 10
        result.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
        result.baseForegroundColor = Theme.primary
        result.baseBackgroundColor = Theme.buttonFill
        result.cornerStyle = .fixed
        result.background.cornerRadius = Theme.buttonCornerRadius
        return result
    }

    @objc
    private func buttonTapped() {
        onTap?()
    }
}

extension Environment {
    var pickerSubtitle: String {
        "\(name) · \(modeDisplayName)"
    }
}
