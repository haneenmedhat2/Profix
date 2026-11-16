//
//  SignupVC.swift
//  Esterad
//
//  Created by Haneen on 18/10/2025.
//

import UIKit
import Combine

class SignupVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameTextField: GeneralTextField!
    @IBOutlet weak var phoneTextField: PhoneTextField!
    @IBOutlet weak var cityTextField: PickerFieldView!
    @IBOutlet weak var passwordTextField: PasswordTextField!
    @IBOutlet weak var confirmPasswordTextField: PasswordTextField!
    @IBOutlet weak var checkBoxButton: UIButton!
    
    //MARK: - Properties -
    
    var viewModel : SignupVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : SignupVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "SignupVC", bundle: nil)
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
        self.title = "create_new_account".localized
        configureProfileImage()
        bindViewModel()
        cityTextField.delegate = self
    }
    
    //MARK: - Image configurations -
    
    private func configureProfileImage() {
        profileImage.layer.cornerRadius = profileImage.frame.width / 2
        profileImage.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCameraTap))
        profileImage.addGestureRecognizer(tap)
    }
    
    //MARK: - CheckBox Button  -
    
    private func updateCheckboxAppearance() {
        viewModel.isChecked.toggle()
        if viewModel.isChecked {
            checkBoxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        } else {
            checkBoxButton.setImage(UIImage(systemName: "square"), for: .normal)
        }
    }
    
    //MARK: - ViewModel Binding -
    
    private func bindViewModel() {
        
        loading(viewModel.isLoadingPublisher)
        
        viewModel.signupPublisher
            .dropFirst()
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                goToVerification(token : result?.data?.token ?? "Token" )
            }
            .store(in: &cancellables)
        
        viewModel.cityPublisher
            .dropFirst()
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                self.showCityPopup()
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
    
    //MARK: - Action -
    
    @IBAction func didTapCheckBox(_ sender: UIButton) {
        updateCheckboxAppearance()
    }
    
    @IBAction func didTapTermsAndConditions(_ sender: UIButton) {
        goToTermsAndConditions()
    }
    
    @IBAction func didTapLogin(_ sender: UIButton) {
        goToLogin()
    }
    
    @IBAction func didTapSignup(_ sender: UIButton) {
        viewModel.validateUserData(model: SignupModel(name: usernameTextField.txtField.text, phone: phoneTextField.txtField.text, countryKey: "0996", cityId: viewModel.selectedCity?.pickerId, password: passwordTextField.txtField.text, confirmPassword: confirmPasswordTextField.txtField.text,avatar: viewModel.image))
    }
    
    @objc func didTapChangeLanguage() {
        showLanguagePopup()
    }
    
    @objc func onCameraTap(){
        let picker = ImagePicker()
        picker.pickImage { [weak self] image, imageData in
            guard let self = self else { return }
            self.profileImage.image = image
            viewModel.image = imageData ?? Data()
            AppHelper.addDashedBorder( to: profileImage)
        }
    }
}

//MARK: - Routes -

extension SignupVC {
    func showLanguagePopup(){
        let vc = LanguagePopUp()
        vc.appear(sender: self)
    }
    
    func goToLogin(){
        popToRoot()
    }
    
    func goToVerification(token : String ){
        let vc = VerificationVC(viewModel: VerificationVM( userToken: token, flow: .signup))
        push(vc)
    }
    
    func goToTermsAndConditions(){
       let vc = TermsConditionsVC(viewModel: TermsVM())
       push(vc)
    }
    
    func showCityPopup(){
        let popup = PickerListPopup()
        popup.pickerList = viewModel.citiesList
        popup.selectedItem = viewModel.selectedCity
        
        popup.onItemSelected = { [weak self] item in
            guard let self = self else { return }
            self.viewModel.selectedCity = item
            self.cityTextField.txtField.text = item?.pickerName
        }
        popup.appear(sender: self)
    }
}

//MARK: - Delegate Confirmation -
extension SignupVC : PickerFieldViewDelegate {
    func pickerFieldViewDidTap(_ view: PickerFieldView) {
        if viewModel.citiesList.isEmpty {
            viewModel.getCities()
        } else {
            showCityPopup()
        }
    }
}
