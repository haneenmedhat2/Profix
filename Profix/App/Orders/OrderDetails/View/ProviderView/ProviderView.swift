//
//  ProviderView.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import UIKit
import Kingfisher

class ProviderView: UIView {

    //MARK: - Outlets -

    @IBOutlet weak var providerLogo: UIImageView!
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerRating: UILabel!
    @IBOutlet weak var orderNum: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    //MARK: - Properites -
     

    //MARK: - Initializer -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewSetup()
    }
    
    //MARK: - Nib file configuration -
    
    func viewSetup(){
        let view = loadViewFromNib()
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)
    }
        
    func loadViewFromNib()-> UIView {
        let nib = UINib(nibName: "ProviderView", bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func setupData(model : OrderDetailsModel){
        providerLogo.kf.setImage(with: URL(string:  model.delegateAvatar ?? ""),options: [.onFailureImage(UIImage(resource: .blankProfile )), .transition(.fade(0.3))])

        providerName.text = model.delegateName
        providerRating.text = model.delegateRate
        orderNum.text =  "order_num".localized + "#" + "\(model.id ?? 0)"
        createdAtLabel.text =  model.createdAt ?? ""
        timeLabel.text = model.time ?? ""
    }
}

