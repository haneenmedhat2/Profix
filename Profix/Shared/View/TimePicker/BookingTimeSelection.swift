import Foundation

enum BookingTimeSelection {
    static func nearest(to proposed: Date, in ranges: [ClosedRange<Date>]) -> Date? {
        let minute = Calendar(identifier: .gregorian).dateInterval(of: .minute, for: proposed)!.start
        return ranges.map { min(max(minute, $0.lowerBound), $0.upperBound) }
            .min { abs($0.timeIntervalSince(minute)) < abs($1.timeIntervalSince(minute)) }
    }
}
