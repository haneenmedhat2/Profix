//
//  TimePickerVC.swift
//  Cleaf
//
//  Created by Haneen on 31/05/2025.
//

import UIKit

class TimePickerVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak private var timePicker: UIDatePicker!
    @IBOutlet weak var selectButton: MainButton!
    
    //MARK: - Properties -
    
    var selectedTime: Date?
    var selectedDate: Date?
    var onTimeSelected: ((Date) -> Void)?
    
    //MARK: - Initializer -

    init(){
        super.init(nibName: "TimePickerVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle  -
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timePicker.datePickerMode = .time

        if let time = selectedTime {
            timePicker.date = time
        }

        setupMinimumTime()
    }

    private func setupMinimumTime() {
        guard let selectedDate = selectedDate else { return }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(selectedDate, inSameDayAs: now) {
            let oneHourLater = calendar.date(byAdding: .hour, value: 1, to: now)
            timePicker.minimumDate = oneHourLater
        } else {
            timePicker.minimumDate = nil
        }
    }
    
    //MARK: - Actions -
    
    @IBAction private func selectPressed(_ sender: UIButton) {
        onTimeSelected?(timePicker.date)
        dismiss(animated: true)
    }
    
    @IBAction private func closePressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
