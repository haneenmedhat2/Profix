//
//  DelegateCell.swift
//  Profix
//
//  Created by Haneen on 01/01/2026.
//

import UIKit
import Kingfisher

class DelegateCell: UICollectionViewCell {

    //MARK: - Outlets -
    
    @IBOutlet weak var delegateIcon: UIImageView!
    @IBOutlet weak var delegateName: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupCell(model: DelegateModel){
        delegateIcon.kf.setImage(with: URL(string: model.avatar ?? ""),options: [.onFailureImage(UIImage(resource: .blankProfile )), .transition(.fade(0.3))])
        delegateName.text = model.name
        rateLabel.text = model.rate
    }
}
