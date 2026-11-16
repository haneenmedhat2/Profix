import UIKit

final class ClockDialView: UIView {
    enum Mode { case hours, minutes }
    var mode: Mode = .hours { didSet { setNeedsDisplay() } }
    var isPM = false { didSet { setNeedsDisplay() } }
    var available: Set<Int> = [] { didSet { setNeedsDisplay() } }
    var selected: Int? { didSet { setNeedsDisplay(); updateAccessibility() } }
    var onSelect: ((Int) -> Void)?
    var onUnavailable: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        semanticContentAttribute = .forceLeftToRight
        isAccessibilityElement = true
        accessibilityTraits = [.adjustable]
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchDial(_:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(touchDial(_:))))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var centerPoint: CGPoint { CGPoint(x: bounds.midX, y: bounds.midY) }
    private var radius: CGFloat { min(bounds.width, bounds.height) / 2 - 24 }

    private func point(for value: Int) -> CGPoint {
        let index = mode == .hours ? value % 12 : value
        let count = mode == .hours ? 12 : 60
        let angle = CGFloat(index) * .pi * 2 / CGFloat(count) - .pi / 2
        let distance = radius
        return CGPoint(x: centerPoint.x + cos(angle) * distance, y: centerPoint.y + sin(angle) * distance)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.secondarySystemBackground.setFill()
        UIBezierPath(ovalIn: bounds.insetBy(dx: 2, dy: 2)).fill()
        if let selected, available.contains(selected) {
            let target = point(for: selected)
            context.setStrokeColor(UIColor.main.cgColor)
            context.setLineWidth(2)
            context.move(to: centerPoint)
            context.addLine(to: target)
            context.strokePath()
            UIColor.main.setFill()
            UIBezierPath(ovalIn: CGRect(x: target.x - 19, y: target.y - 19, width: 38, height: 38)).fill()
            UIBezierPath(ovalIn: CGRect(x: centerPoint.x - 4, y: centerPoint.y - 4, width: 8, height: 8)).fill()
        }
        let values = mode == .hours ? Array((isPM ? 12 : 0)..<(isPM ? 24 : 12)) : Array(0..<60)
        for value in values {
            let enabled = available.contains(value)
            let isSelected = selected == value && enabled
            let location = point(for: value)
            // Keep neighboring ticks/labels from drawing over an exact-minute selection, e.g. 24 beside 25.
            if mode == .minutes, let selected, available.contains(selected), value != selected {
                let selectionPoint = point(for: selected)
                if hypot(location.x - selectionPoint.x, location.y - selectionPoint.y) < 29 { continue }
            }
            let color: UIColor = isSelected ? .white : (enabled ? .label : .tertiaryLabel)
            if mode == .minutes && value % 5 != 0 && !isSelected {
                color.withAlphaComponent(enabled ? 0.7 : 0.4).setFill()
                UIBezierPath(ovalIn: CGRect(x: location.x - 2, y: location.y - 2, width: 4, height: 4)).fill()
                continue
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: mode == .hours ? 18 : 15, weight: isSelected ? .semibold : .regular),
                .foregroundColor: color
            ]
            let text = (mode == .hours ? String(value % 12 == 0 ? 12 : value % 12) : String(format: "%02d", value)) as NSString
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: location.x - size.width / 2, y: location.y - size.height / 2), withAttributes: attributes)
        }
    }

    @objc private func touchDial(_ gesture: UIGestureRecognizer) {
        if let pan = gesture as? UIPanGestureRecognizer,
           pan.state != .began && pan.state != .changed && pan.state != .ended { return }
        let touch = gesture.location(in: self)
        let dx = touch.x - centerPoint.x
        let dy = touch.y - centerPoint.y
        let distance = hypot(dx, dy)
        guard distance > radius * 0.3, distance <= radius + 26 else { return }
        var angle = atan2(dy, dx) + .pi / 2
        if angle < 0 { angle += 2 * .pi }
        let count = mode == .hours ? 12 : 60
        var value = Int((angle / (2 * .pi) * CGFloat(count)).rounded()) % count
        if mode == .hours {
            value += isPM ? 12 : 0
        }
        guard available.contains(value) else {
            if gesture.state == .ended { onUnavailable?() }
            return
        }
        // Commit the selected value when the user releases the dial.
        if gesture.state == .ended { onSelect?(value) }
    }

    private func updateAccessibility() {
        accessibilityLabel = (mode == .hours ? "clock_choose_hour" : "clock_choose_minute").localized
        accessibilityValue = selected.map {
            mode == .hours ? "\($0 % 12 == 0 ? 12 : $0 % 12) \((isPM ? "clock_pm" : "clock_am").localized)" : String(format: "%02d", $0)
        } ?? ""
        accessibilityHint = "clock_accessibility_hint".localized
    }

    override func accessibilityIncrement() { adjust(forward: true) }
    override func accessibilityDecrement() { adjust(forward: false) }

    private func adjust(forward: Bool) {
        let values = available.sorted()
        let next = forward ? values.first(where: { $0 > (selected ?? -1) }) : values.last(where: { $0 < (selected ?? 60) })
        if let next { onSelect?(next) }
    }
}
