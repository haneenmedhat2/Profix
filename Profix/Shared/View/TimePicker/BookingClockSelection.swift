import Foundation

struct BookingClockSelection {
    let day: Date
    let ranges: [ClosedRange<Date>]
    private let calendar = Calendar(identifier: .gregorian)

    func date(hour: Int, minute: Int) -> Date? {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    func minutes(for hour: Int) -> [Int] {
        (0..<60).filter { minute in
            guard let date = date(hour: hour, minute: minute) else { return false }
            return ranges.contains { $0.contains(date) }
        }
    }

    var hours: [Int] { (0..<24).filter { !minutes(for: $0).isEmpty } }
}
