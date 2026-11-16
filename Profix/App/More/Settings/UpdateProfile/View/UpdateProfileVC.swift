//
//  UpdateProfileVC.swift
//  Esterad
//
//  Created by Haneen on 03/11/2025.
//

import UIKit
import Combine
import Kingfisher

class UpdateProfileVC: BaseViewController {
    
    //MARK: - Outlets -

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameTextField: GeneralTextField!
    @IBOutlet weak var cityTextField: PickerFieldView!
    
    //MARK: - Properties -
    
    var viewModel : UpdateProfileVM

    //MARK: - Initializer -
    
    init(viewModel : UpdateProfileVM){
        self.viewModel = viewModel
        super.init(nibName: "UpdateProfileVC", bundle: nil)
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
    
    private func initialConfiguration(){
        self.title = "edit_profile".localized
        configureProfileImage()
        setupUserData()
        bindViewModel()
        cityTextField.delegate = self

    }
    
    private func configureProfileImage() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCameraTap))
        profileImage.addGestureRecognizer(tap)

        let overlayImageView = UIImageView(image: UIImage(resource: .profilePic))
        overlayImageView.frame = profileImage.bounds
        overlayImageView.contentMode = .scaleAspectFit
        overlayImageView.alpha = 0.8
        overlayImageView.isUserInteractionEnabled = false

        profileImage.addSubview(overlayImageView)
    }
    
    private func setupUserData(){
        guard let user = UserDefaults.user else { return }
        cityTextField.txtField.text = user.cityName
        usernameTextField.txtField.text = user.name ?? ""
        profileImage.kf.setImage(with: URL(string: user.avatar ?? ""),options: [.onFailureImage(UIImage(resource: .blankProfile )), .transition(.fade(0.3))])
        viewModel.selectedCity = CityModel(id: user.cityId, name: user.cityName)
    }
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.updateProfilePublisher
            .compactMap{ $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                showLottiePopup(title: result.message)
            }
            .store(in: &cancellables)
        
        viewModel.cityPublisher
            .compactMap { $0 }
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
    
    //MARK: - Actions -
    
    @IBAction func didTapConfirmUpdate(_ sender: UIButton) {
        let username = usernameTextField.txtField.text
        viewModel.validateUserData(model: UpdateProfileModel(avatar: viewModel.image,name: username, cityId: viewModel.selectedCity?.pickerId))
    }
    
    @objc func onCameraTap(){
        let picker = ImagePicker()
        picker.pickImage { [weak self] image, imageData in
            guard let self = self else { return }
            self.profileImage.image = image
            viewModel.image = imageData ?? Data()
        }
    }
}

//MARK: - Routes -
extension UpdateProfileVC {
    
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
    
    func showLottiePopup(title: String){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title)
        vc.onPopupHidden = { [weak self] in
            guard let self = self else { return }
            pop()
        }
    }
}

//MARK: - Delegate Confirmation -
extension UpdateProfileVC : PickerFieldViewDelegate {
    func pickerFieldViewDidTap(_ view: PickerFieldView) {
        if viewModel.citiesList.isEmpty {
            viewModel.getCities()
        } else {
            showCityPopup()
        }
    }
}
