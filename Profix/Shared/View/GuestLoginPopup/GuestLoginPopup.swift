//
//  GuestLoginPopup.swift
//  Waraqa
//
//  Created by Haneen on 05/10/2025.
//

import UIKit

class GuestLoginPopup: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    //MARK: - Properites -
    
    //MARK: - Initializer  -
    
    init() {
        super.init(nibName: "GuestLoginPopup", bundle: nil)
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapBackView))
        backView.addGestureRecognizer(tap)
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
            }
            self.removeFromParent()
        }
    }
    
    //MARK: - Action -
    
    @IBAction func didTapSignin(_ sender: UIButton) {
        let vc = LoginVC(viewModel: LoginVM())
        let nav  = BaseNav(rootViewController: vc)
        AppHelper.changeWindowRoot(vc: nav)
    }
    
    @objc func didTapBackView() {
        hide()
    }
}


