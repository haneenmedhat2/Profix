//
//  ChooseRateCell.swift
//  Profix
//
//  Created by Haneen on 05/01/2026.
//

import UIKit

class ChooseRateCell: UICollectionViewCell {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var radioBtn: RadioButton!
    
    //MARK: - Properties -
    
    var didTapOnRadioBtn: ((String) -> Void)?
    
    //MARK: - Cell Configuration -
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(title : String){
        titleLabel.text = title
    }
}
