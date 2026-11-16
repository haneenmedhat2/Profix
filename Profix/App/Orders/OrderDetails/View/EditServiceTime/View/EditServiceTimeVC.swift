//
//  EditServiceTimeVC.swift
//  Profix
//
//  Created by Haneen on 19/01/2026.
//

import UIKit
import Combine

class EditServiceTimeVC: BaseViewController {

    //MARK: - Outlets -
    
    @IBOutlet weak var datePickerView: DatePickerTextFieldView!
    @IBOutlet weak var timePickerView: TimePickerTextFieldView!
    
    //MARK: - Properties -
    
    var viewModel : EditServiceTimeVMProtocol
    var delegate : EditServiceTimeProtocol?
    
    //MARK: - Initializer -
    
    init(viewModel :EditServiceTimeVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "EditServiceTimeVC", bundle: nil)
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
        self.title = "edit_service_time".localized
        bindViewModel()
        datePickerView.configure(in: self)
        timePickerView.configure(in: self)
        
        datePickerView.onDateSelected = { [weak self] date in
             guard let self = self else { return }
             self.timePickerView.selectedDate = date
         }
    }
    
    //MARK: - ViewModel binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.editTimePublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] response in
                guard let self = self else { return }
                self.showLottiePopup(title: response.message)
            }
            .store(in: &cancellables)
        
        viewModel.validationPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.show(errorMessage: result.localizedDescription)
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @IBAction func didTapSend(_ sender: UIButton) {
        let date = datePickerView.textField.text
        let time = timePickerView.textField.text
        
        let _ = viewModel.validateUserData(date: date, time: time)
    }

}

//MARK: - Routes -

extension EditServiceTimeVC {
    
    func showLottiePopup(title: String){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title, type: .normal)
        vc.onPopupHidden = { [weak self] in
            guard let self else { return }
            self.delegate?.didEditTime()
            self.pop(animated: true)
        }
    }
}

//MARK: - Delegate Protocol -

protocol EditServiceTimeProtocol : AnyObject {
    func didEditTime()
}
