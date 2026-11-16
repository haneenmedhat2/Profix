//
//  LoginVC.swift
//  Esterad
//
//  Created by Haneen on 15/10/2025.
//

import UIKit
import Combine

class LoginVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var phoneTextField: PhoneTextField!
    @IBOutlet weak var passwordTextField: PasswordTextField!
    @IBOutlet weak var languageBtn: IconTextGeneralButton!
    
    //MARK: - Properties -
    
    let viewModel : LoginVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : LoginVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "LoginVC", bundle: nil)
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
    
    func initialConfiguration(){
        self.title = "login".localized
        bindViewModel()
        requestNotifications()
        
        languageBtn.onTap = { [weak self] in
            guard let self else { return }
            self.showLanguagePopup()
        }
    }

    //MARK: - ViewModel Binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.loginPublisher
            .compactMap{ $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                result.key == .needActive ?  self.goToVerification(token : result.data?.token ?? "" ) : self.goToHome()
            }
            .store(in: &cancellables)
        
        viewModel.validationPublisher
            .compactMap{ $0 }
            .sinkOnMain{ [weak self] error in
                guard let self = self else { return }
                show(errorMessage: error.localizedDescription)
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    private func requestNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
    }
    
    //MARK: - Action -
    
    @IBAction func didTapForgetPassword(_ sender: UIButton) {
        goToForgetPassword()
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        let phone = phoneTextField.txtField.text
        let password = passwordTextField.txtField.text
        viewModel.validateInputs(model: LoginModel(phone: phone, password: password))
    }
    
    @IBAction func didTapGuest(_ sender: UIButton) {
        Session.isLogin = false
        Session.isGuest = true
        let vc = AppTabBarController.create()
        AppHelper.changeWindowRoot(vc: vc)
    }
    
    @IBAction func didTapCreateAccount(_ sender: UIButton) {
        goToSignup()
    }
}

//MARK: - Routes -

extension LoginVC {
    func showLanguagePopup(){
        let vc = LanguagePopUp()
        vc.appear(sender: self)
    }
    
    func goToSignup(){
        let vc = SignupVC(viewModel: SignupVM())
        push(vc)
    }
    
    func goToForgetPassword(){
        let vc = ForgetPasswordVC(viewModel: ForgetPasswordVM())
        push(vc)
    }
    
    func goToHome() {
        Session.isLogin = true
        Session.isGuest = false
        let vc = AppTabBarController.create()
        AppHelper.changeWindowRoot(vc: vc)
    }
    
    func goToVerification(token : String ){
        let vc = VerificationVC(viewModel: VerificationVM( userToken: token, flow: .signup))
        push(vc)
    }
}
