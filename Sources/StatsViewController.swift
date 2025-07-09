//
//  StatsViewController.swift
//  DevApp
//
//  Created by Bo Gosmer on 08/07/2025.
//

import Combine
import UIKit
import WeDoBooksSDK

final class StatsViewController: UIViewController {
    private var cancellables: Set<AnyCancellable> = []
    
    private let yearStatsButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "This year"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let dayStatsButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Single day"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let checkoutStatsButton = {
        let result = UIButton(configuration: .standardConfiguration(for: "Single checkout"))
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
 
    // MARK: Override vars
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }
    
    // MARK: View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .label
        
        setupViewHierarchy()
        setupControlActions()
    }
    
    // MARK: Private functions
    
    private func setupViewHierarchy() {
        view.addSubview(yearStatsButton)
        view.addSubview(dayStatsButton)
        view.addSubview(checkoutStatsButton)
        
        NSLayoutConstraint.activate([
            yearStatsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            yearStatsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            yearStatsButton.heightAnchor.constraint(equalToConstant: 50),
            yearStatsButton.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        NSLayoutConstraint.activate([
            dayStatsButton.topAnchor.constraint(equalTo: yearStatsButton.bottomAnchor, constant: 40),
            dayStatsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            dayStatsButton.heightAnchor.constraint(equalToConstant: 50),
            dayStatsButton.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        NSLayoutConstraint.activate([
            checkoutStatsButton.topAnchor.constraint(equalTo: dayStatsButton.bottomAnchor, constant: 40),
            checkoutStatsButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            checkoutStatsButton.heightAnchor.constraint(equalToConstant: 50),
            checkoutStatsButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupControlActions() {
        yearStatsButton.addTarget(self, action: #selector(yearStatsButtonTapped), for: .touchUpInside)
        dayStatsButton.addTarget(self, action: #selector(dayStatsButtonTapped), for: .touchUpInside)
        checkoutStatsButton.addTarget(self, action: #selector(checkoutStatsButtonTapped), for: .touchUpInside)
    }
    
    @objc
    private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func yearStatsButtonTapped() {
        setAllButtons(enabled: false)
        
        let year = Calendar.current.component(.year, from: Date())
        WeDoBooksFacade.shared
            .userOperations
            .totalStats(year: String(year))
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                guard !stats.isEmpty, let self else {
                    self?.setAllButtons(enabled: true)
                    return
                }
                let summedEntry = sumStats(stats)
                let vc = StatsEntryViewController(entry: summedEntry, title: String(year))
                navigationController?.pushViewController(vc, animated: true)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    self.setAllButtons(enabled: true)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc
    private func dayStatsButtonTapped() {
        setAllButtons(enabled: false)
        
        let pickerVC = DatePickerViewController { [weak self] datePicked in
            self?.showStatsForDate(datePicked)
        }
        pickerVC.modalPresentationStyle = .formSheet
        pickerVC.presentationController?.delegate = self
        present(pickerVC, animated: true)
    }
    
    @objc
    private func checkoutStatsButtonTapped() {
        setAllButtons(enabled: false)
        
        try? WeDoBooksFacade.shared
            .bookOperations
            .observeCheckouts()
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { status in
                if case .failure(let error) = status {
                    print("observeCheckouts failed: \(error)")
                }
            } receiveValue: { [weak self] checkouts in
                let sorted = checkouts.sorted { $0.title < $1.title }
                self?.presentCheckoutPicker(checkouts: sorted)
            }
            .store(in: &cancellables)
    }
    
    private func setAllButtons(enabled to: Bool) {
        yearStatsButton.isEnabled = to
        dayStatsButton.isEnabled = to
        checkoutStatsButton.isEnabled = to
    }
    
    private func showStatsForDate(_ date: Date) {
        let year = Calendar.current.component(.year, from: date)
        WeDoBooksFacade.shared
            .userOperations
            .totalStats(year: String(year))
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                guard !stats.isEmpty else {
                    self?.setAllButtons(enabled: true)
                    return
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let formatted = formatter.string(from: date)
                let kv = stats.first { $0.key == formatted }
                if let entry = kv?.value {
                    let vc = StatsEntryViewController(entry: entry, title: formatted)
                    self?.navigationController?.pushViewController(vc, animated: true)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        self?.setAllButtons(enabled: true)
                    }
                } else {
                    print("no entry for \(formatted)")
                    self?.setAllButtons(enabled: true)
                }

            }
            .store(in: &cancellables)
    }
    
    private func presentCheckoutPicker(checkouts: [Checkout]) {
        let items = checkouts.map {
            ($0.title, $0.fixedAuthors.joined(separator: ", "), $0.isbn)
        }
        let picker = CheckoutPickerViewController(items: items) { [weak self] selectedIndex in
            let selected = checkouts[selectedIndex]
            self?.fetchStatsForCheckout(selected)
        }

        picker.modalPresentationStyle = .formSheet
        picker.presentationController?.delegate = self
        present(picker, animated: true)
    }
    
    private func fetchStatsForCheckout(_ checkout: Checkout) {
        WeDoBooksFacade.shared
            .userOperations
            .totalStats(checkoutId: checkout.id)
            .prefix(1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                guard let self else { return }
                let summedStats = self.sumStats(stats)
                let vc = StatsEntryViewController(entry: summedStats, title: checkout.title)
                navigationController?.pushViewController(vc, animated: true)
                setAllButtons(enabled: true)
            }
            .store(in: &cancellables)
    }
    
    private func sumStats(_ stats: [String: StatEntry]) -> StatEntry {
        let result = stats.reduce(StatEntry.empty) { partialResult, tuple in
            let entry = tuple.value
            return StatEntry(
                audioMinutes: partialResult.audioMinutes + entry.audioMinutes,
                ebookMinutes: partialResult.ebookMinutes + entry.ebookMinutes,
                minutesRead: partialResult.minutesRead + entry.minutesRead,
                audioSeconds: partialResult.audioSeconds + entry.audioSeconds,
                ebookSeconds: partialResult.ebookSeconds + entry.ebookSeconds,
                secondsRead: partialResult.secondsRead + entry.secondsRead,
                wordsRead: partialResult.wordsRead + entry.wordsRead
            )
        }
        return result
    }
}

extension StatsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        setAllButtons(enabled: true)
    }
}
