//
//  CategoryHeaderView.swift
//  Esterad
//
//  Created by Haneen on 13/11/2025.
//

import Foundation
import UIKit

final class CollectionHeaderView: UICollectionReusableView {
    
    // MARK: - Properties -
    
    static let headerIdentifier = "CollectionHeaderView"
    static let elementKind = UICollectionView.elementKindSectionHeader
    
    var headerType: HeaderTypes = .services
    weak var delegate: HeaderViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .myMediumFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var showAllButton: UnderlineButton = {
        let button = UnderlineButton()
        button.setTitle("view_all", for: .normal)
        button.setTitleColor(.main, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(didTapShowAll), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Initializers -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup -
    
    private func setupUI() {
        backgroundColor = .clear
        
        titleStack.addArrangedSubview(titleLabel)
        
        addSubview(titleStack)
        addSubview(showAllButton)
        
        NSLayoutConstraint.activate([
            
            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            titleStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8),

            showAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            showAllButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            showAllButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            showAllButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8)
        ])
    }
    
    // MARK: - Actions -
    
    @objc private func didTapShowAll() {
        delegate?.didTapShowAll(headerType: headerType)
    }
}

extension CollectionHeaderView {
    func configure(
        title: String,
        headerType: HeaderTypes
    ) {
        titleLabel.text = title
        showAllButton.isHidden = headerType.isShowAllHidden
        self.headerType = headerType
    }
}

// MARK: - Header View Delegation -

protocol HeaderViewDelegate: AnyObject {
    func didTapShowAll(headerType : HeaderTypes? )
}
