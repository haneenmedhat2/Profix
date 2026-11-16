import Foundation

struct ProviderDayPeriods: Codable {
    let date: String
    let closeToday: Bool
    let periods: [ProviderDayPeriod]

    enum CodingKeys: String, CodingKey {
        case date, periods
        case closeToday = "close_today"
    }

    static func unrestrictedPeriods(on date: String, now: Date = Date()) -> [ProviderDayPeriod] {
        let periods = (0..<24).map { hour in
            let from = String(format: "%02d:00", hour)
            let to = String(format: "%02d:00", (hour + 1) % 24)
            return ProviderDayPeriod(from: from, to: to, label: "\(from) - \(to)", isClosed: false, isOpen: true)
        }
        return periods.filter {
            $0.selectableRange(on: date, now: now) != nil
        }
    }

    // Apply the API schedule only to its date and exclude periods with no remaining selectable minutes.
    func availablePeriods(on bookingDate: String, now: Date = Date()) -> [ProviderDayPeriod]? {
        guard bookingDate == date else { return nil }
        guard !closeToday else { return [] }
        return periods.filter {
            $0.isOpen && !$0.isClosed && $0.selectableRange(on: date, now: now) != nil
        }
    }
}

struct ProviderDayPeriod: Codable, Equatable {
    let from: String
    let to: String
    let label: String
    let isClosed: Bool
    let isOpen: Bool

    enum CodingKeys: String, CodingKey {
        case from, to, label
        case isClosed = "is_closed"
        case isOpen = "is_open"
    }

    func selectableRange(on date: String, now: Date = Date()) -> ClosedRange<Date>? {
        guard isOpen, !isClosed, let start = startDate(on: date),
              var end = dateTime(on: date, time: to), from != to else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        if end < start {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: end) else { return nil }
            end = nextDay
        }
        // Booking times carry minutes only; round up so an already elapsed minute cannot be sent.
        let minuteStart = calendar.dateInterval(of: .minute, for: now)!.start
        let earliest = max(start, minuteStart < now ? minuteStart.addingTimeInterval(60) : minuteStart)
        let latest = calendar.dateInterval(of: .minute, for: end.addingTimeInterval(-1))!.start
        return earliest <= latest ? earliest...latest : nil
    }

    func allows(time: String, on date: String, now: Date = Date()) -> Bool {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd hh:mm a"
        formatter.isLenient = false
        guard let selection = formatter.date(from: "\(date) \(time)"),
              let range = selectableRange(on: date, now: now) else { return false }
        return range.contains(selection)
    }

    func bookingTime(on date: String) -> String? {
        guard let start = startDate(on: date) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: start)
    }

    func startDate(on date: String) -> Date? {
        dateTime(on: date, time: from)
    }

    private func dateTime(on date: String, time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.isLenient = false
        return formatter.date(from: "\(date) \(time)")
    }
}
