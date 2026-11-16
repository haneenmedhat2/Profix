import UIKit

final class ClockTimePickerVC: UIViewController {
    var availableTimeRanges: (() -> [ClosedRange<Date>])?
    var selectedTime: Date?
    var onTimeSelected: ((Date) -> Void)?

    private let dial = ClockDialView()
    private let hourButton = UIButton(type: .system)
    private let minuteButton = UIButton(type: .system)
    private let periodControl = UISegmentedControl(items: ["clock_am".localized, "clock_pm".localized])
    private let confirmButton = UIButton(type: .system)
    private let messageLabel = UILabel()
    private let calendar = Calendar(identifier: .gregorian)
    private var model: BookingClockSelection?
    private var hour = 0
    private var minute = 0
    private var refreshTimer: Timer?

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        let ranges = availableTimeRanges?() ?? []
        if let initial = BookingTimeSelection.nearest(to: selectedTime ?? Date(), in: ranges) {
            hour = calendar.component(.hour, from: initial)
            minute = calendar.component(.minute, from: initial)
        }
        refreshAvailability()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvailability), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.refreshAvailability() }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    deinit {
        refreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        let title = UILabel()
        title.text = "select_time".localized
        title.font = .myBoldFont(ofSize: 18)
        title.textAlignment = .natural
        stack.addArrangedSubview(title)

        let colon = UILabel()
        colon.text = ":"
        colon.font = .systemFont(ofSize: 30, weight: .semibold)
        colon.textAlignment = .center
        let timeRow = UIStackView(arrangedSubviews: [hourButton, colon, minuteButton])
        timeRow.spacing = 12
        timeRow.distribution = .fill
        timeRow.semanticContentAttribute = .forceLeftToRight
        for button in [hourButton, minuteButton] {
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 30, weight: .semibold)
            button.layer.cornerRadius = 12
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        }
        hourButton.widthAnchor.constraint(equalTo: minuteButton.widthAnchor).isActive = true
        colon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        hourButton.addTarget(self, action: #selector(chooseHours), for: .touchUpInside)
        minuteButton.addTarget(self, action: #selector(chooseMinutes), for: .touchUpInside)
        stack.addArrangedSubview(timeRow)
        periodControl.semanticContentAttribute = .forceLeftToRight
        periodControl.selectedSegmentTintColor = UIColor.main.withAlphaComponent(0.15)
        periodControl.addTarget(self, action: #selector(changePeriod), for: .valueChanged)
        stack.addArrangedSubview(periodControl)

        messageLabel.numberOfLines = 0
        messageLabel.font = .myRegularFont(ofSize: 13)
        messageLabel.textAlignment = .center
        stack.addArrangedSubview(messageLabel)
        dial.translatesAutoresizingMaskIntoConstraints = false
        dial.heightAnchor.constraint(equalTo: dial.widthAnchor).isActive = true
        stack.addArrangedSubview(dial)
        dial.onSelect = { [weak self] value in self?.select(value) }
        dial.onUnavailable = { [weak self] in
            self?.messageLabel.text = "clock_time_unavailable".localized
            self?.messageLabel.textColor = .systemRed
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        let legend = UILabel()
        legend.numberOfLines = 0
        legend.font = .myRegularFont(ofSize: 12)
        legend.textAlignment = .center
        legend.text = "clock_unavailable_hint".localized
        legend.textColor = .secondaryLabel
        stack.addArrangedSubview(legend)
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        confirmButton.setTitle("confirm".localized, for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.backgroundColor = .main
        confirmButton.layer.cornerRadius = 10
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [cancelButton, confirmButton])
        actions.distribution = .fillEqually
        actions.spacing = 12
        actions.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stack.addArrangedSubview(actions)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            scroll.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),
            card.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            card.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            card.topAnchor.constraint(greaterThanOrEqualTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            card.bottomAnchor.constraint(lessThanOrEqualTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        // Center short cards, while allowing the full picker to scroll on smaller screens.
        card.centerYAnchor.constraint(equalTo: scroll.contentLayoutGuide.centerYAnchor).isActive = true
        let height = scroll.contentLayoutGuide.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        height.priority = .defaultLow
        height.isActive = true
    }

    @objc private func refreshAvailability() {
        let ranges = availableTimeRanges?() ?? []
        if let day = ranges.first?.lowerBound {
            model = BookingClockSelection(day: day, ranges: ranges)
        } else {
            model = nil
        }
        render()
    }

    private func render() {
        let availableMinutes = model?.minutes(for: hour) ?? []
        let valid = availableMinutes.contains(minute)
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        hourButton.setTitle(String(format: "%02d", displayHour), for: .normal)
        periodControl.selectedSegmentIndex = hour / 12
        let hours = model?.hours ?? []
        periodControl.setEnabled(hours.contains { $0 < 12 }, forSegmentAt: 0)
        periodControl.setEnabled(hours.contains { $0 >= 12 }, forSegmentAt: 1)
        dial.isPM = hour >= 12
        minuteButton.setTitle(String(format: "%02d", minute), for: .normal)
        hourButton.accessibilityLabel = "clock_choose_hour".localized
        minuteButton.accessibilityLabel = "clock_choose_minute".localized
        hourButton.accessibilityValue = "\(displayHour) \((hour >= 12 ? "clock_pm" : "clock_am").localized)"
        minuteButton.accessibilityValue = String(format: "%02d", minute)
        for (button, active) in [(hourButton, dial.mode == .hours), (minuteButton, dial.mode == .minutes)] {
            button.backgroundColor = active ? UIColor.main.withAlphaComponent(0.15) : .secondarySystemBackground
            button.setTitleColor(active ? .main : .label, for: .normal)
        }
        dial.available = Set(dial.mode == .hours ? hours.filter { ($0 >= 12) == (hour >= 12) } : availableMinutes)
        dial.selected = dial.mode == .hours ? hour : minute
        confirmButton.isEnabled = valid
        confirmButton.alpha = valid ? 1 : 0.4
        messageLabel.textColor = model == nil ? .systemRed : .secondaryLabel
        messageLabel.text = model == nil ? "no_available_booking_hours".localized :
            (dial.mode == .hours ? "clock_choose_hour" : "clock_choose_minute").localized
    }

    private func select(_ value: Int) {
        refreshAvailability()
        if dial.mode == .hours {
            guard let minutes = model?.minutes(for: value), !minutes.isEmpty else { return }
            hour = value
            if !minutes.contains(minute) { minute = minutes[0] }
        } else {
            guard model?.minutes(for: hour).contains(value) == true else { return }
            minute = value
        }
        UISelectionFeedbackGenerator().selectionChanged()
        render()
    }

    @objc private func changePeriod() {
        hour = hour % 12 + periodControl.selectedSegmentIndex * 12
        dial.mode = .hours
        refreshAvailability()
    }

    @objc private func chooseHours() { dial.mode = .hours; refreshAvailability() }
    @objc private func chooseMinutes() { dial.mode = .minutes; refreshAvailability() }
    @objc private func cancel() { dismiss(animated: true) }
    @objc private func confirm() {
        refreshAvailability()
        guard let model, model.minutes(for: hour).contains(minute), let date = model.date(hour: hour, minute: minute) else { return }
        let completion = onTimeSelected
        dismiss(animated: true) { completion?(date) }
    }
}
