//
//  StatsEntryViewController.swift
//  DevApp
//
//  Created by Bo Gosmer on 08/07/2025.
//

import UIKit
import WeDoBooksSDK

final class StatsEntryViewController: UIViewController {
    private let entry: StatEntry

    public init(entry: StatEntry, title: String) {
        self.entry = entry
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let labels: [UILabel] = [
            label("Audio Minutes", entry.audioMinutes),
            label("Ebook Minutes", entry.ebookMinutes),
            label("Total Minutes Read", entry.minutesRead),
            label("Audio Seconds", entry.audioSeconds),
            label("Ebook Seconds", entry.ebookSeconds),
            label("Total Seconds Read", entry.secondsRead),
            label("Words Read", entry.wordsRead)
        ]

        labels.forEach(stack.addArrangedSubview)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func label(_ title: String, _ value: Int) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "\(title): \(value)"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }
}

