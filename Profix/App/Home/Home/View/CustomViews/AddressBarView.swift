//
//  AddressBarView.swift
//  Profix
//
//  Created by Haneen on 25/01/2026.
//
import Foundation
import UIKit

final class AddressBarView: UIStackView {

    private let addressLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        axis = .horizontal
        spacing = 6
        alignment = .center
        isUserInteractionEnabled = true

        let locationImageView = UIImageView(image: UIImage(resource: .location06))
        locationImageView.contentMode = .scaleAspectFit
        locationImageView.tintColor = .black
        locationImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        locationImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        addressLabel.font = UIFont.myMediumFont(ofSize: 14)
        addressLabel.textColor = .white
        addressLabel.numberOfLines = 1

        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        let arrowImageView = UIImageView(image: UIImage(resource: .arrowDown02))
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.tintColor = .white
        arrowImageView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true

        addArrangedSubview(locationImageView)
        addArrangedSubview(addressLabel)
        addArrangedSubview(arrowImageView)

        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: addressLabel.trailingAnchor, constant: 4)
        ])
    }

    func updateAddress(_ text: String) {
        addressLabel.text = text
        activityIndicator.stopAnimating()
    }

    func showLoading() {
        activityIndicator.startAnimating()
    }
}
