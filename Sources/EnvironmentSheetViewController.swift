//
//  EnvironmentSheetViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 08/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import UIKit

final class EnvironmentSheetViewController: UIViewController {
    var onPick: ((Environment) -> Void)?

    private static let detentIdentifier = UISheetPresentationController.Detent.Identifier("environmentList")
    private static let cellIdentifier = "EnvironmentCell"
    private static let titleTopInset: CGFloat = 32
    private static let tableTopSpacing: CGFloat = 16

    private let environments: [Environment]
    private let selected: Environment
    private var measuredContentHeight: CGFloat = 0

    private let titleLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "Run the sample app against"
        result.font = .systemFont(ofSize: 20, weight: .bold)
        result.textColor = .label
        result.numberOfLines = 0
        return result
    }()

    private let tableView: UITableView = {
        let result = UITableView(frame: .zero, style: .insetGrouped)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.backgroundColor = .clear
        result.rowHeight = UITableView.automaticDimension
        result.estimatedRowHeight = 58
        result.sectionHeaderTopPadding = 0
        result.alwaysBounceVertical = false
        return result
    }()

    init(environments: [Environment], selected: Environment) {
        self.environments = environments
        self.selected = selected

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)

        setupViewHierarchy()

        view.layoutIfNeeded()
        configureSheet()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Rows only report their real height once laid out, and Dynamic Type can change it later.
        guard abs(tableView.contentSize.height - measuredContentHeight) > 0.5 else { return }
        measuredContentHeight = tableView.contentSize.height
        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    // MARK: Private functions

    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.titleTopInset),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Self.tableTopSpacing),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureSheet() {
        guard let sheet = sheetPresentationController else { return }
        sheet.detents = [.medium()]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 20
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
    }
}

// MARK: - UITableViewDataSource

extension EnvironmentSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        environments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let environment = environments[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = environment.displayName
        content.secondaryText = environment.pickerSubtitle
        cell.contentConfiguration = content
        cell.accessoryType = environment.id == selected.id ? .checkmark : .none
        cell.tintColor = Theme.primary

        return cell
    }
}

// MARK: - UITableViewDelegate

extension EnvironmentSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let environment = environments[indexPath.row]
        let pick = onPick
        dismiss(animated: true) { pick?(environment) }
    }
}
