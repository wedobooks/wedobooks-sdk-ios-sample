//
//  EasyAccessView.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 03/07/2025.
//

import UIKit
import WeDoBooksSDK

protocol EasyAccessViewDelegate: AnyObject {
    func closeTapped()
    func didActivate(checkout: Checkout)
}

final class EasyAccessView: UIView {
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorsLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let activateButton: UIButton = .init(type: .system)
    
    private var data: EasyAccessData?
    
    weak var delegate: EasyAccessViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .secondarySystemFill
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        gestureRecognizers = [UITapGestureRecognizer(target: self, action: #selector(activateTapped))]
        
        // Cover
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.layer.cornerRadius = 4
        
        // Labels
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        authorsLabel.font = UIFont.systemFont(ofSize: 12)
        authorsLabel.textAlignment = .center
        authorsLabel.textColor = .secondaryLabel
        authorsLabel.numberOfLines = 1
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, authorsLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Close Button
        let xImage = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
        closeButton.setImage(xImage, for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        // Horizontal Stack
        let horizontalStack = UIStackView(arrangedSubviews: [coverImageView, textStack, closeButton])
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 8
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress View
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .secondarySystemBackground
        progressView.progressTintColor = .label
        
        // Layout
        let mainStack = UIStackView(arrangedSubviews: [horizontalStack, progressView])
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            coverImageView.widthAnchor.constraint(equalToConstant: 40),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor),
            
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    func configure(data: EasyAccessData) {
        self.data = data
        
        titleLabel.text = data.checkout.title
        if data.checkout.author.count <= 1 {
            authorsLabel.text = data.checkout.fixedAuthor
        } else {
            if data.checkout.fixedAuthors.count > 2 {
                authorsLabel.text = [data.checkout.fixedAuthors[0...data.checkout.fixedAuthors.count - 2].joined(separator: ", "), data.checkout.fixedAuthors.last!].joined(separator: " & ")
            } else {
                authorsLabel.text = data.checkout.fixedAuthors.joined(separator: " & ")
            }
        }
        coverImageView.image = UIImage(named: "CustomCover")
        progressView.progress = data.progress
    }
    
    @objc private func closeTapped() {
        delegate?.closeTapped()
    }
    
    @objc private func activateTapped() {
        guard let checkout = data?.checkout else { return }
        delegate?.didActivate(checkout: checkout)
    }
}
