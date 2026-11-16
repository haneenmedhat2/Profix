//
//  DatePickerTextFieldView.swift
//  Cleaf
//
//  Created by Haneen on 31/05/2025.
//

import UIKit

class DatePickerTextFieldView: UIView {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var requiredLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var txtFieldStackView: UIStackView!
    @IBOutlet weak var optionalBtn: UIButton!
    
    //MARK: - Properties -
    
    weak var hostingViewController: UIViewController?
    var onDateSelected: ((Date) -> Void)?
    var isRequired  = true
    var selectedDate: Date? {
        didSet {
            updateDateText()
        }
    }
    
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
    
    //MARK: - Initializer -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
    }
    
    //MARK: - Nib file configuration -
    
    private func loadFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "DatePickerTextFieldView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        setupTap()
    }
    
    private func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showDatePicker))
        textField.addGestureRecognizer(tap)
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear
    }
    
    func configure(in viewController: UIViewController) {
        self.hostingViewController = viewController
    }
    
    private func updateDateText() {
        guard let date = selectedDate else { return }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") 
        formatter.dateFormat = "yyyy-MM-dd"
        textField.text = formatter.string(from: date)
    }

    @objc private func showDatePicker() {
         guard let parent = hostingViewController else { return }
         let vc = DatePickerVC()
         vc.modalPresentationStyle = .overFullScreen
         vc.selectedDate = self.selectedDate
         vc.onDateSelected = { [weak self] date in
             self?.selectedDate = date
             self?.onDateSelected?(date)
         }
         parent.present(vc, animated: true)
     }

}
