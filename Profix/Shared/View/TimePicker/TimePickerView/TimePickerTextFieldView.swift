//
//  TimePickerTextFieldView.swift
//  Cleaf
//
//  Created by Haneen on 31/05/2025.
//

import UIKit

class TimePickerTextFieldView: UIView {

    //MARK: - Outlets -
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var requiredLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var txtFieldStackView: UIStackView!
    @IBOutlet weak var optionalBtn: UIButton!
    
    //MARK: - Properties -
    
    private weak var hostingViewController : UIViewController?
    var isRequired = true
    var selectedtime : Date? {
        didSet{
            updateTimeField()
        }
    }
    var selectedDate: Date?
    var onTimeSelected: ((Date) -> Void)?
    // Return true when the host presents its own available-hours picker.
    var onShowTimePicker: (() -> Bool)?
    
    @IBInspectable var isRequiredProperty : Bool = true {
        didSet{
            isRequired = isRequiredProperty
            if isRequired {
                requiredLabel.textColor = .red
            } else{
                requiredLabel.textColor = .gray
            }
            
        }
    }
    @IBInspectable var titleTxt : String = "" {
        didSet{
            titleLabel.text = titleTxt.localized
        }
    }
    
    @IBInspectable var requiredTxt : String = "" {
        didSet{
            requiredLabel.text = requiredTxt.localized
        }
    }
    
    @IBInspectable var placeHolderTxt : String = "" {
        didSet{
            textField.placeholder = placeHolderTxt.localized
        }
    }
    
    @IBInspectable var isLabelHidden : Bool = false{
        didSet{
            requiredLabel.isHidden = isLabelHidden
        }
    }
    
    @IBInspectable var isButtonHidden : Bool = true {
        didSet{
            optionalBtn.isHidden = isButtonHidden
        }
    }
    
    @IBInspectable var buttonIcon : UIImage? {
        didSet{
            optionalBtn.setImage(buttonIcon, for: .normal)
        }
    }
    
    @IBInspectable var keyboardTypeRawValue: Int = 0 {
        didSet {
            if let type = UIKeyboardType(rawValue: keyboardTypeRawValue) {
                textField.keyboardType = type
            }
        }
    }
    
    @IBInspectable var stackBackgroundColor : UIColor? {
        didSet{
            txtFieldStackView.backgroundColor = stackBackgroundColor
        }
    }
    
    //MARK: - Initializer  -
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureNib()
    }
    
    //MARK: - Nib File Configuration -
    
    private func configureNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "TimePickerTextFieldView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        setupTap()
    }
    
    private func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showTimePicker))
        textField.addGestureRecognizer(tap)
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear
    }
    
    func configure(in viewController: UIViewController) {
        self.hostingViewController = viewController
    }
    
    private func updateTimeField() {
        guard let time = selectedtime else {
            textField.text = nil
            return
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        textField.text = formatter.string(from: time)
    }
    
    @objc private func showTimePicker() {
           if onShowTimePicker?() == true { return }
           guard let parent = hostingViewController else { return }

           let vc = TimePickerVC()
           vc.modalPresentationStyle = .overFullScreen
           vc.selectedDate = self.selectedDate
           vc.selectedTime = self.selectedtime
           vc.onTimeSelected = { [weak self] time in
               self?.selectedtime = time
               self?.onTimeSelected?(time)
           }
           parent.present(vc, animated: true)
       }
}
