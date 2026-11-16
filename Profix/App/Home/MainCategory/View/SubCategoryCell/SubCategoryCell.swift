//
//  SubCategoryCell.swift
//  Cleaf
//
//  Created by Haneen on 02/06/2025.
//

import UIKit

class SubCategoryCell: UICollectionViewCell {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var soonLabel: UILabel!
    
    //MARK: - Properties -
    
    //MARK: - Nib File Configuration -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        soonLabel.isHidden = true
    }
    
    //MARK: - Setup Cell -
    
    
    func setupCell(model : SubCategoryModel, isSelected : Bool){
        cellLabel.text = model.name
        updateCellSelection(isCellSelected : isSelected)
        soonLabel.isHidden = model.status != "pending"
    }
    
    func updateCellSelection(isCellSelected : Bool ){
        if isCellSelected {
            cellContentView.backgroundColor = .white
            cellContentView.layer.borderColor = UIColor.main.cgColor
            cellLabel.textColor = .main
            
        } else {
            cellContentView.backgroundColor = .offWhite
            cellContentView.layer.borderColor = UIColor.offWhite.cgColor
            cellLabel.textColor = .gray
        }
    }
}
