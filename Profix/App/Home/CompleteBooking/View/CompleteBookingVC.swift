//
//  CompleteBookingVC.swift
//  Profix
//
//  Created by Haneen on 11/01/2026.
//

import UIKit
import Combine

class CompleteBookingVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var datePickerView: DatePickerTextFieldView!
    @IBOutlet weak var timePickerView: TimePickerTextFieldView!
    @IBOutlet weak var locationTextField: GeneralTextField!
    @IBOutlet weak var couponTextFeild: GeneralTextField!
    @IBOutlet weak var problemDescTextView: DropDownTextView!
    @IBOutlet weak var problemImagesView: ComplaintImagesView!
    
    //MARK: - Properties -
    
    var viewModel : CompleteBookingVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel :CompleteBookingVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "CompleteBookingVC", bundle: nil)
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
        self.title = "complete_booking".localized
        bindViewModel()
        datePickerView.configure(in: self)
        timePickerView.configure(in: self)
        datePickerView.textField.delegate = self
        timePickerView.textField.delegate = self
        timePickerView.onShowTimePicker = { [weak self] in
            self?.showAvailableHours() ?? true
        }
        
        datePickerView.onDateSelected = { [weak self] date in
             guard let self = self else { return }
             self.timePickerView.selectedDate = date
             self.timePickerView.selectedtime = nil
             self.updateTimePlaceholder()
         }
        
        locationTextField.txtField.isEnabled = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(onLocationTapped))
        locationTextField.addGestureRecognizer(tap)
        
    }
    
    //MARK: - ViewModel binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.orderEnquiryPublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] _ in
                guard let self = self else { return }
                self.goToOrderSummary()
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
        let address = locationTextField.txtField.text
        let desc = problemDescTextView.actualText
        if let coupon = couponTextFeild.txtField.text, !coupon.trimWhiteSpace().isEmpty {
            viewModel.orderModel.coupon = coupon
        } else {
            viewModel.orderModel.coupon = nil

        }
        viewModel.orderModel.images = problemImagesView.imagesList.map{ $0.data }
        let _ = viewModel.validateUserData(date: date, time: time, address: address, desc: desc)
    }
    
    @objc func onLocationTapped(){
        goToBookingLocation()
    }
}

//MARK: - Routes -

extension CompleteBookingVC {
    
    func goToOrderSummary(){
        let vc = OrderSummary(viewModel: OrderSummaryVM(orderModel: viewModel.orderModel))
        push(vc, animated: true)
    }
    
    func goToBookingLocation(){
        let vc = BookingLocationVC(viewModel: BookingLocationVM())
        vc.viewModel.onLocationSelected = { [weak self ] address in
            guard let self = self else { return }
               self.locationTextField.txtField.text = address.desc
            self.viewModel.orderModel.lat = address.lat
            self.viewModel.orderModel.long = address.long
            self.viewModel.orderModel.description = address.desc
           }
        
        push(vc, animated: true)
    }
}

// MARK: - Available booking hours

extension CompleteBookingVC: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // These two fields are selected through their pickers, never typed manually.
        return false
    }

    private func updateTimePlaceholder() {
        let date = datePickerView.textField.text ?? ""
        if !date.isEmpty && viewModel.availablePeriods(for: date).isEmpty {
            timePickerView.textField.placeholder = "no_available_booking_hours".localized
        } else {
            timePickerView.textField.placeholder = timePickerView.placeHolderTxt.localized
        }
    }

    private func showAvailableHours() -> Bool {
        guard let date = datePickerView.textField.text, !date.isEmpty else {
            show(errorMessage: ValidationError.emptyExecutionDate.localizedDescription)
            return true
        }
        let periods = viewModel.availablePeriods(for: date)
        guard !periods.isEmpty else {
            timePickerView.selectedtime = nil
            updateTimePlaceholder()
            show(errorMessage: "no_available_booking_hours".localized)
            return true
        }

        let picker = ClockTimePickerVC()
        picker.modalPresentationStyle = .overFullScreen
        picker.availableTimeRanges = { [weak self] in
            self?.viewModel.availablePeriods(for: date).compactMap { $0.selectableRange(on: date) } ?? []
        }
        picker.selectedTime = timePickerView.selectedtime
        picker.onTimeSelected = { [weak self] time in
            self?.timePickerView.selectedtime = time
        }
        present(picker, animated: true)
        return true
    }
}
