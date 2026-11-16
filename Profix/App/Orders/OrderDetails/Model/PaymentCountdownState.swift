import Foundation

struct PaymentCountdownState {
    let remainingSeconds: Int
    let message: String

    var clock: String {
        let seconds = max(0, remainingSeconds)
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

enum AcceptanceCountdown {
    static func seconds(timer: Int?, hours: Int?, minutes: Int?, seconds: Int?, clock: String?) -> Int? {
        // An explicit zero from the server is authoritative, even if other fields are stale.
        if let timer { return max(0, timer) }
        if hours != nil || minutes != nil || seconds != nil {
            return max(0, hours ?? 0) * 3600 + max(0, minutes ?? 0) * 60 + max(0, seconds ?? 0)
        }
        guard let parts = clock?.split(separator: ":"), parts.count == 3 else { return nil }
        let values = parts.compactMap { Int($0) }
        guard values.count == 3, values.allSatisfy({ $0 >= 0 }), values[1] < 60, values[2] < 60 else { return nil }
        return values[0] * 3600 + values[1] * 60 + values[2]
    }
}

struct PaymentCountdownDeadline {
    private let deadline: TimeInterval

    init(seconds: Int, now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        deadline = now + Double(max(0, seconds))
    }

    func remainingSeconds(now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Int {
        Int(max(0, ceil(deadline - now)))
    }
}
