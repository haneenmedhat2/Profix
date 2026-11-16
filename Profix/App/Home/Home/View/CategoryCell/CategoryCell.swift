//
//  CategoryCell.swift
//  Profix
//
//  Created by Haneen on 31/12/2025.
//

import UIKit
import Kingfisher

final class HomeCategoryCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "HomeCategoryCollectionCell"

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(named: "StateColor")
        view.layer.cornerRadius = 12
        return view
    }()

    private let categoryIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .redraw
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        return imageView
    }()

    private let categoryTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .natural
        return label
    }()

    private let soonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(white: 0.333, alpha: 1)
        label.textAlignment = .natural
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let labelsStack = UIStackView(arrangedSubviews: [categoryTitle, soonLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.alignment = .center

        let contentStack = UIStackView(arrangedSubviews: [categoryIcon, labelsStack])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .center

        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            categoryIcon.widthAnchor.constraint(equalToConstant: 50),
            categoryIcon.heightAnchor.constraint(equalToConstant: 50),
            contentStack.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        categoryIcon.kf.cancelDownloadTask()
        categoryIcon.image = nil
        categoryTitle.text = nil
        soonLabel.text = nil
        soonLabel.isHidden = true
    }

    func configure(model: HomeCategory) {
        categoryIcon.kf.setImage(
            with: URL(string: model.image),
            placeholder: UIImage(resource: .electricity)
        )
        categoryTitle.text = model.name
        soonLabel.text = model.status == .pending ? "soon".localized : nil
        soonLabel.isHidden = model.status != .pending
    }
}

class CategoryCell: UITableViewCell {

    //MARK: - Outlets -
    
    @IBOutlet weak var categorIcon: UIImageView!
    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var soonLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupCell(model: HomeCategory){
        categorIcon.kf.setImage(with: URL(string: model.image), placeholder: UIImage(resource: .electricity))

        categoryTitle.text = model.name

        if model.status == .pending {
            soonLabel.isHidden = false
            soonLabel.text = "soon".localized
        } else {
            soonLabel.isHidden = true
        }
    }
}
