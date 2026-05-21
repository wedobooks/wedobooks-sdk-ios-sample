//
//  DevicesViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 21/05/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Combine
import UIKit
import WeDoBooksSDK

private enum DevicesSection {
    case all
}

private struct DeviceRow: Hashable {
    let id: String
    let name: String
    let isActive: Bool
}

private final class DeviceRowCell: UITableViewCell {
    static let reuseIdentifier = "DeviceRowCell"

    private let titleLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.font = .preferredFont(forTextStyle: .body)
        result.numberOfLines = 0
        return result
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(row: DeviceRow) {
        let activeSuffix = row.isActive ? " (Active)" : ""
        titleLabel.text = row.name + activeSuffix
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}

final class DevicesViewController: UIViewController, UITableViewDelegate {
    private var cancellables: Set<AnyCancellable> = []
    private var selectedDeviceIds: Set<String> = []
    private var isRemoving = false

    private let tableView: UITableView = {
        let result = UITableView(frame: .zero, style: .plain)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.allowsMultipleSelection = true
        return result
    }()

    private let emptyStateLabel: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.text = "No devices found"
        result.textAlignment = .center
        result.textColor = .secondaryLabel
        result.font = .preferredFont(forTextStyle: .body)
        result.isHidden = true
        return result
    }()

    private let removeSelectedButton = UIButton(title: "Remove selected")

    private var rows: [DeviceRow] = []

    private lazy var dataSource = UITableViewDiffableDataSource<DevicesSection, DeviceRow>(tableView: tableView) { tableView, indexPath, row in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviceRowCell.reuseIdentifier, for: indexPath) as? DeviceRowCell else {
            return UITableViewCell()
        }
        cell.configure(row: row)
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Devices"
        view.backgroundColor = .systemBackground
        setupViewHierarchy()

        tableView.register(DeviceRowCell.self, forCellReuseIdentifier: DeviceRowCell.reuseIdentifier)
        tableView.delegate = self

        removeSelectedButton.addTarget(self, action: #selector(removeSelectedTapped), for: .touchUpInside)
        updateRemoveButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeDevices()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellables = []
    }

    private func setupViewHierarchy() {
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(removeSelectedButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: removeSelectedButton.topAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            removeSelectedButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            removeSelectedButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            removeSelectedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func observeDevices() {
        WeDoBooksFacade.shared
            .devicesManager
            .observeDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] observation in
                self?.applyDevices(observation)
            }
            .store(in: &cancellables)
    }

    private func applyDevices(_ observation: DevicesData?) {
        let activeId = observation?.activeDevice
        rows = observation?.devices.map { device in
            DeviceRow(id: device.id, name: device.name, isActive: device.id == activeId)
        } ?? []

        rows.sort {
            if $0.isActive != $1.isActive {
                return $0.isActive
            }
            return $0.id < $1.id
        }

        let presentIds = Set(rows.map(\.id))
        selectedDeviceIds.formIntersection(presentIds)

        var snapshot = NSDiffableDataSourceSnapshot<DevicesSection, DeviceRow>()
        snapshot.appendSections([.all])
        snapshot.appendItems(rows)
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            self?.restoreSelection()
        }

        let hasDevices = !rows.isEmpty
        emptyStateLabel.isHidden = hasDevices
        removeSelectedButton.isHidden = !hasDevices
        updateRemoveButtonState()
    }

    private func restoreSelection() {
        for (index, row) in rows.enumerated() where selectedDeviceIds.contains(row.id) {
            tableView.selectRow(
                at: IndexPath(row: index, section: 0),
                animated: false,
                scrollPosition: .none
            )
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isRemoving, let row = dataSource.itemIdentifier(for: indexPath) else { return }
        selectedDeviceIds.insert(row.id)
        updateRemoveButtonState()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !isRemoving, let row = dataSource.itemIdentifier(for: indexPath) else { return }
        selectedDeviceIds.remove(row.id)
        updateRemoveButtonState()
    }

    private func updateRemoveButtonState() {
        let count = selectedDeviceIds.count
        let title: String
        if isRemoving {
            title = "Removing..."
        } else if count == 0 {
            title = "Remove selected"
        } else {
            title = "Remove selected (\(count))"
        }
        removeSelectedButton.configuration = UIButton.Configuration.standardConfiguration(for: title)
        removeSelectedButton.isEnabled = !isRemoving && count > 0
    }

    @objc
    private func removeSelectedTapped() {
        guard !isRemoving, !selectedDeviceIds.isEmpty else { return }
        let idsToRemove = Array(selectedDeviceIds)

        isRemoving = true
        tableView.allowsSelection = false
        updateRemoveButtonState()

        Task { @MainActor [weak self] in
            guard let self else { return }

            let result = await WeDoBooksFacade.shared.devicesManager.removeDevices(with: idsToRemove)

            isRemoving = false
            tableView.allowsSelection = true

            if case .failure(let error) = result {
                showErrorAlert(error)
            } else {
                selectedDeviceIds.subtract(idsToRemove)
            }

            updateRemoveButtonState()
        }
    }

    private func showErrorAlert(_ error: DeviceManagementError) {
        let alert = UIAlertController(
            title: "Failed to remove devices",
            message: String(describing: error),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
