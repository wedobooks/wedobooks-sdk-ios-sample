//
//  DownloadedBooksViewController.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 25/07/2025.
//

import UIKit
import WeDoBooksSDK

enum DownloadedBooksSection {
    case all
}

struct DownloadedBookItem: Hashable {
    let isbn: String
}

final class DownloadedBooksViewController: UIViewController {
    private static let cellIdentifier = "DownloadedBookCell"
    
    private let tableView: UITableView = {
        let result = UITableView()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.allowsSelection = false
        return result
    }()
    
    private lazy var dataSource: UITableViewDiffableDataSource<DownloadedBooksSection, DownloadedBookItem> = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
        let result: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        var config = result.defaultContentConfiguration()
        config.text = item.isbn
        result.contentConfiguration = config
        return result
    }
    
    // MARK: - Object life cycle
    
    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewHierarchy()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        
        let books = (try? WeDoBooksFacade.shared.storageOperations.getAllDownloadedBooks()) ?? []
        let items = books.sorted().map(DownloadedBookItem.init)
        
        var snapshot = NSDiffableDataSourceSnapshot<DownloadedBooksSection, DownloadedBookItem>()
        snapshot.appendSections([DownloadedBooksSection.all])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Private functions
    
    private func setupViewHierarchy() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
