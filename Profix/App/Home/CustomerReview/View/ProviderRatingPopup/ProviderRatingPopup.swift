//
//  ProviderRatingPopup.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import UIKit
import Cosmos

class ProviderRatingPopup: BaseViewController {

    //MARK: - Outlets -
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var commentTextView: DropDownTextView!
    
    //MARK: - Properties -
    
    var delegate : RatingPopupProtocol?
    
    //MARK: - Initializer  -
    
    init() {
        super.init(nibName: "ProviderRatingPopup", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfiguration()
    }
    
    //MARK: - Initial Configuration -
    
    func initialConfiguration(){
        configView()
    }
    
    //MARK: - View Configuration -
    
    func configView(){
        self.view.backgroundColor = .clear
        self.backView.backgroundColor  = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.contentView.alpha = 0
        self.contentView.layer.cornerRadius = 12
        contentView.isUserInteractionEnabled = true
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(onBackViewTapped))
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(backTap)
    }

    func appear(sender:UIViewController){
        sender.present(self, animated: false){
            self.show()
        }
    }
    
    func show(){
        UIView.animate(withDuration: 1, delay: 0.1){
            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    
    func hide(){
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false){
            }
            self.removeFromParent()
        }
    }
        
    //MARK: - Actions -
    
    @IBAction func confirmlBtnTapped(_ sender: UIButton){
        let rate = ratingView.rating
        delegate?.didTapConfirm(rate: rate, comment: commentTextView.textView.text)
        self.hide()
    }
    
    @objc private func onBackViewTapped() {
        self.hide()
    }
}

//MARK: - Delegate Protocol -

protocol RatingPopupProtocol : AnyObject {
    func didTapConfirm(rate : Double , comment : String?)
}
