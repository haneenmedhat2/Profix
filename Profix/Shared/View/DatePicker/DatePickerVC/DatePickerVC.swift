//
//  DatePickerVC.swift
//  Cleaf
//
//  Created by Haneen on 31/05/2025.
//

import UIKit

class DatePickerVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak private var calendar: UIDatePicker!
    @IBOutlet weak var selectButton: MainButton!
    
    //MARK: - Properties -
    
    var selectedDate: Date?
    var onDateSelected: ((Date) -> Void)?
    
    //MARK: - Initializer -

    init(){
        super.init(nibName: "DatePickerVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle  -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendar.datePickerMode = .date
        calendar.preferredDatePickerStyle = .inline
        calendar.minimumDate = Date()
        if let date = selectedDate {
            calendar.date = date
        }
    }
    
    //MARK: - Actions -
    @IBAction private func selectPressed(_ sender: UIButton) {
        onDateSelected?(calendar.date)
        dismiss(animated: true)
    }
    
    @IBAction private func closePressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
