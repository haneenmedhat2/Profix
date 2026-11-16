//
//  ProfileVC.swift
//  Esterad
//
//  Created by Haneen on 02/11/2025.
//

import UIKit
import Kingfisher
import Combine

class ProfileVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameTextField: GeneralTextField!
    @IBOutlet weak var phoneTextField: PhoneTextField!
    @IBOutlet weak var cityTextField: GeneralTextField!
    
    //MARK: - Properties -
    
    let viewModel : ProfileVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : ProfileVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "ProfileVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad(){
        super.viewDidLoad()
        initialConfiguration()
    }
    
    //MARK: - Initial Setup -
    
    func initialConfiguration() {
        self.title = "profile".localized
        setupUserData()
        viewModel.profileRequest()
        bindViewModel()
        phoneTextField.txtField.isEnabled = false
        usernameTextField.txtField.isEnabled = false
        cityTextField.txtField.isEnabled = false
        
        phoneTextField.txtField.textColor = .hint
        usernameTextField.txtField.textColor = .hint
        cityTextField.txtField.textColor = .hint

    }
    
    private func bindViewModel() {
        viewModel.profile
            .sinkOnMain { [weak self] user in
                guard let self = self else { return }
                self.setupUserData()
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Setup Data -
    
    func setupUserData() {
        guard let user = UserDefaults.user else { return }
        
        usernameTextField.txtField.text = user.name ?? ""
        phoneTextField.txtField.text = user.phone ?? ""
        cityTextField.txtField.text = user.cityName ?? ""
        
        profileImage.kf.setImage(with: URL(string: user.avatar ?? ""),options: [.onFailureImage(UIImage(resource: .blankProfile )), .transition(.fade(0.3))])
    }
}
