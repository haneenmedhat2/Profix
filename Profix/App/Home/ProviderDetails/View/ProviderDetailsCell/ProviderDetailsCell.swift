//
//  ProviderDetailsCell.swift
//  Profix
//
//  Created by Haneen on 07/01/2026.
//

import UIKit
import Kingfisher

class ProviderDetailsCell: UICollectionViewCell {

    //MARK: - Outlets -
    
    @IBOutlet weak var providerImage: UIImageView!
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerRating: UILabel!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var numOfServices: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setupCell(provider: DelegateModel){
        providerImage.kf.setImage(with: URL(string: provider.avatar ?? ""),options: [.onFailureImage(UIImage(resource: .blankProfile )), .transition(.fade(0.3))])
        providerName.text = provider.name
        providerRating.text = provider.rate
        numOfServices.text = provider.numOrders
        if let description = provider.description , !description.trimWhiteSpace().isEmpty {
            descTextView.text = description
        } else {
            descTextView.text = "no_provider_bio".localized

        }
    }
}
