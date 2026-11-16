//
//  OrderReasonSelectionCell.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import UIKit

class OrderReasonSelectionCell: UITableViewCell {

    //MARK: - Outlets -
    
    @IBOutlet weak var reasonLabel : UILabel!
    @IBOutlet weak var selectionImg: UIImageView!
    
    //MARK: - Properties -
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    //MARK: - Cell setup -

    func setupCell(model : CancelReasonsModel){
        reasonLabel.text = model.reason
        
        if model.isSelected  {
            reasonLabel.textColor = .main
            selectionImg.tintColor = .main
            selectionImg.image = UIImage(systemName: "circle.inset.filled")
        } else {
            reasonLabel.textColor = .border
            selectionImg.tintColor = .border
            selectionImg.image = UIImage(systemName: "circle")
        }
    }
}
