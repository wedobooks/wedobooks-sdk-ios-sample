//
//  DatePickerViewController.swift
//  DevApp
//
//  Created by Bo Gosmer on 08/07/2025.
//

import UIKit

final class DatePickerViewController: UIViewController {
    private let datePicker = UIDatePicker()
    private let onDatePicked: (Date) -> Void

    init(initialDate: Date = .now, onDatePicked: @escaping (Date) -> Void) {
        self.onDatePicked = onDatePicked
        super.init(nibName: nil, bundle: nil)
        datePicker.date = initialDate
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .wheels // for modal feel

        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.label, for: .normal)

        let stack = UIStackView(arrangedSubviews: [datePicker, button])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func doneTapped() {
        onDatePicked(datePicker.date)
        dismiss(animated: true)
    }
}
