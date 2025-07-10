//
//  CheckoutPickerViewController.swift
//  DevApp
//
//  Created by Bo Gosmer on 08/07/2025.
//

import UIKit

final class CheckoutPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let items: [(title: String, subtitle: String, isbn: String)]
    private let onPick: ((Int) -> Void)
    private let tableView = UITableView()

    init(items: [(String, String, String)], onPick: @escaping (Int) -> Void) {
        self.items = items
        self.onPick = onPick
        super.init(nibName: nil, bundle: nil)
        self.title = "Choose Item"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.subtitle + "\n" + item.isbn
        config.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = config
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            self.onPick(indexPath.row)
        }
    }
}
