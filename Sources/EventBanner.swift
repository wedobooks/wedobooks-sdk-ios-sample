//
//  EventBanner.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 23/10/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

/// Short messages shown at the top of the window, above the SDK reader and player, so SDK
/// callbacks and events can be seen without a debugger. Messages stack and fade out on their own.
enum EventBanner {
    private static let visibleDuration: TimeInterval = 3

    static func show(_ message: String) {
        print(message)
        Task { @MainActor in
            present(message)
        }
    }

    @MainActor
    private static func present(_ message: String) {
        guard let window = keyWindow() else { return }
        let banner = BannerView(message: message)
        stack(in: window).addArrangedSubview(banner)
        UIAccessibility.post(notification: .announcement, argument: message)

        DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) {
            UIView.animate(withDuration: 0.25, animations: { banner.alpha = 0 }) { _ in
                banner.removeFromSuperview()
            }
        }
    }

    @MainActor
    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    @MainActor
    private static func stack(in window: UIWindow) -> BannerStackView {
        if let existing = window.subviews.compactMap({ $0 as? BannerStackView }).first {
            window.bringSubviewToFront(existing)
            return existing
        }
        let stack = BannerStackView()
        window.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
        ])
        return stack
    }
}

private final class BannerStackView: UIStackView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 8
        isUserInteractionEnabled = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class BannerView: UIView {
    init(message: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 10

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = message
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
