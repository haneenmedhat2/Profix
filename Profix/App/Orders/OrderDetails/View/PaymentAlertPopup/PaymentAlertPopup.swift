//
//  PaymentAlertPopup.swift
//  Profix
//
//  Created by Haneen on 18/01/2026.
//

import UIKit

class PaymentAlertPopup: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    //MARK: - Properites -
    
    var delegate : PaymentAlertPopupProtocol?
    
    //MARK: - Initializer  -
    
    init() {
        super.init(nibName: "PaymentAlertPopup", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false){
                self.delegate?.didTapConfirm()
            }
            self.removeFromParent()
        }
    }
    
    func setupView(paymentTimeoutMessage: String) {
        loadViewIfNeeded()
        titleLabel.text = paymentTimeoutMessage
    }
    
    //MARK: - Action -

    @IBAction func didTapConfirm(_ sender: UIButton) {
        hide()
    }
}

//MARK: - PaymentAlertPopup Protocol -

protocol PaymentAlertPopupProtocol : AnyObject {
   func didTapConfirm()
}
