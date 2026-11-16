import UIKit

final class PaymentCountdownView: UIView {
    private let messageLabel = UILabel()
    private let clockLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        isHidden = true
        backgroundColor = UIColor(named: "AlphaRed")
        layer.cornerRadius = 12
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .natural
        messageLabel.font = UIFont.myRegularFont(ofSize: 14)
        messageLabel.textColor = UIColor(named: "errorColor")
        clockLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .semibold)
        clockLabel.textColor = UIColor(named: "errorColor")
        clockLabel.textAlignment = .center
        clockLabel.semanticContentAttribute = .forceLeftToRight

        let stack = UIStackView(arrangedSubviews: [messageLabel, clockLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        let bottom = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        bottom.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            bottom
        ])
    }

    func configure(state: PaymentCountdownState?, showsZero: Bool = false) {
        isHidden = state == nil || (!showsZero && (state?.remainingSeconds ?? 0) <= 0)
        messageLabel.text = state?.message
        clockLabel.text = state?.clock
    }
}
