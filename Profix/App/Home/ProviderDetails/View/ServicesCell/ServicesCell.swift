//
//  ServicesCell.swift
//  Profix
//
//  Created by Haneen on 07/01/2026.
//

import UIKit

class ServicesCell: UICollectionViewCell {

    //MARK: - Outlets -
    
    @IBOutlet weak var checkBoxImage: UIImageView!
    @IBOutlet weak var serviceName: UILabel!
    @IBOutlet weak var servicePrice: UILabel!
    @IBOutlet weak var descTextView: UITextView!

    private lazy var quantityRow: UIStackView = makeQuantityRow()
    private let quantityValueLabel = UILabel()
    private lazy var executionCountBadge: UIView = makeExecutionCountBadge()
    private let executionCountLabel = UILabel()
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?
   
    //MARK: - Properties -

    var mode : ServiceCellMode = .full {
        didSet {
            configureView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupQuantityView()
        setupExecutionCountBadge()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        checkBoxImage.image = UIImage(systemName: "square")
        descTextView.text = nil
        serviceName.text = nil
        servicePrice.text = nil
        quantityRow.isHidden = true
        executionCountBadge.isHidden = true
        onIncrement = nil
        onDecrement = nil
    }

    
    func configureView(){
        switch mode {
        case .full:
            checkBoxImage.isHidden = false
            descTextView.isHidden = false
        case .simple:
            checkBoxImage.isHidden = true
            descTextView.isHidden = true
            quantityRow.isHidden = true
        }
    }
    
    func setupCell(service: Services, displayName: String? = nil){
        serviceName.text = displayName ?? service.subcategoryName
        servicePrice.text = service.price?.toPrice
        
        if let desc = service.description , !desc.trimWhiteSpace().isEmpty {
            descTextView.text = desc
        } else {
            descTextView.text = "no_service_description".localized
        }
    }
    
    func updateCellSelection(isSelected: Bool){
        checkBoxImage.image = isSelected
        ? UIImage(systemName: "checkmark.square")
        : UIImage(systemName: "square")
    }

    func updateQuantity(_ quantity: Int) {
        quantityValueLabel.text = "\(quantity)"
        quantityRow.isHidden = mode == .simple
    }

    func showExecutionCount(_ count: Int) {
        executionCountLabel.text = "× \(count)"
        executionCountBadge.accessibilityLabel = String(
            format: "execution_count_accessibility".localized,
            count
        )
        executionCountBadge.isHidden = false
    }

    private func setupQuantityView() {
        guard let servicesStack = descTextView.superview as? UIStackView else { return }
        servicesStack.addArrangedSubview(quantityRow)
        NSLayoutConstraint.activate([
            quantityRow.widthAnchor.constraint(equalTo: servicesStack.widthAnchor),
            quantityRow.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupExecutionCountBadge() {
        guard let infoStack = serviceName.superview as? UIStackView,
              let nameIndex = infoStack.arrangedSubviews.firstIndex(of: serviceName) else { return }
        infoStack.insertArrangedSubview(executionCountBadge, at: nameIndex + 1)
    }

    private func makeExecutionCountBadge() -> UIView {
        executionCountLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        executionCountLabel.textColor = .main
        executionCountLabel.textAlignment = .center
        executionCountLabel.translatesAutoresizingMaskIntoConstraints = false

        let badge = UIView()
        badge.backgroundColor = UIColor.main.withAlphaComponent(0.1)
        badge.layer.borderColor = UIColor.main.withAlphaComponent(0.25).cgColor
        badge.layer.borderWidth = 1
        badge.layer.cornerRadius = 9
        badge.isAccessibilityElement = true
        badge.isHidden = true
        badge.addSubview(executionCountLabel)

        NSLayoutConstraint.activate([
            executionCountLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 8),
            executionCountLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -8),
            executionCountLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            executionCountLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4)
        ])
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        return badge
    }

    private func makeQuantityRow() -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = "service_execution_count".localized
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let counter = makeCounterView()
        let row = UIStackView(arrangedSubviews: [titleLabel, spacer, counter])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isHidden = true
        return row
    }

    private func makeCounterView() -> UIView {
        let decrementButton = makeQuantityButton(systemName: "minus", action: #selector(didTapDecrement))
        let incrementButton = makeQuantityButton(systemName: "plus", action: #selector(didTapIncrement))
        quantityValueLabel.textAlignment = .center
        quantityValueLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        quantityValueLabel.textColor = .main
        quantityValueLabel.widthAnchor.constraint(equalToConstant: 34).isActive = true

        let stack = UIStackView(arrangedSubviews: [decrementButton, quantityValueLabel, incrementButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = UIColor.main.withAlphaComponent(0.08)
        container.layer.borderColor = UIColor.main.withAlphaComponent(0.25).cgColor
        container.layer.borderWidth = 1
        container.layer.cornerRadius = 12
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 5),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -5)
        ])
        return container
    }

    private func makeQuantityButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .main
        button.layer.cornerRadius = 6
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func didTapIncrement() {
        onIncrement?()
    }

    @objc private func didTapDecrement() {
        onDecrement?()
    }
}
