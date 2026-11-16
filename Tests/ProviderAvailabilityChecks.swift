import Foundation

@main
enum ProviderAvailabilityChecks {
    static func main() throws {
        let periods = (0..<24).map { hour in
            ProviderDayPeriod(
                from: String(format: "%02d:00", hour),
                to: String(format: "%02d:00", (hour + 1) % 24),
                label: String(format: "%02d:00 - %02d:00", hour, (hour + 1) % 24),
                isClosed: (1...3).contains(hour), isOpen: !(1...3).contains(hour)
            )
        }
        let schedule = ProviderDayPeriods(date: "2026-10-14", closeToday: false, periods: periods)
        let previousDay = periods[0].startDate(on: "2026-10-13")!
        let available = schedule.availablePeriods(on: "2026-10-14", now: previousDay)!
        assert(available.count == 21)
        assert(!available.contains { ["01:00", "02:00", "03:00"].contains($0.from) })
        assert(available.last?.to == "00:00")
        assert(available.last?.bookingTime(on: schedule.date) == "11:00 PM")
        assert(available.first?.bookingTime(on: schedule.date) == "12:00 AM")
        assert(schedule.availablePeriods(on: "2026-10-15") == nil)

        let futurePeriods = ProviderDayPeriods.unrestrictedPeriods(on: "2026-10-15", now: previousDay)
        assert(futurePeriods.count == 24)
        assert(futurePeriods.first?.label == "00:00 - 01:00")
        assert(futurePeriods.last?.label == "23:00 - 00:00")
        assert(ProviderDayPeriods.unrestrictedPeriods(on: "invalid", now: previousDay).isEmpty)

        let closed = ProviderDayPeriods(date: schedule.date, closeToday: true, periods: periods)
        assert(closed.availablePeriods(on: schedule.date)?.isEmpty == true)
        let now = periods[15].startDate(on: schedule.date)!
        assert(schedule.availablePeriods(on: schedule.date, now: now)?.first?.from == "15:00")
        assert(ProviderDayPeriods.unrestrictedPeriods(on: schedule.date, now: now).first?.from == "15:00")
        let halfPast = now.addingTimeInterval(30 * 60)
        assert(schedule.availablePeriods(on: schedule.date, now: halfPast)?.first?.from == "15:00")
        assert(ProviderDayPeriods.unrestrictedPeriods(on: schedule.date, now: halfPast).first?.from == "15:00")
        let endOfDay = periods[23].startDate(on: schedule.date)!.addingTimeInterval(30 * 60)
        assert(schedule.availablePeriods(on: schedule.date, now: endOfDay)?.last?.from == "23:00")
        assert(schedule.availablePeriods(on: schedule.date, now: previousDay)?.count == 21)

        let ten = periods[10]
        assert(ten.allows(time: "10:24 AM", on: schedule.date, now: previousDay))
        assert(ten.allows(time: "10:59 AM", on: schedule.date, now: previousDay))
        assert(!ten.allows(time: "11:00 AM", on: schedule.date, now: previousDay))
        assert(!periods[1].allows(time: "01:24 AM", on: schedule.date, now: previousDay))
        let currentTime = ten.startDate(on: schedule.date)!.addingTimeInterval(23 * 60 + 30)
        assert(ten.allows(time: "10:24 AM", on: schedule.date, now: currentTime))
        assert(!ten.allows(time: "10:23 AM", on: schedule.date, now: currentTime))
        assert(ten.selectableRange(on: schedule.date, now: currentTime)?.lowerBound ==
               ten.startDate(on: schedule.date)!.addingTimeInterval(24 * 60))
        assert(periods[23].allows(time: "11:59 PM", on: schedule.date, now: previousDay))
        assert(!periods[23].allows(time: "12:00 AM", on: schedule.date, now: previousDay))
        let finalSeconds = periods[23].startDate(on: schedule.date)!.addingTimeInterval(59 * 60 + 30)
        assert(schedule.availablePeriods(on: schedule.date, now: finalSeconds)?.isEmpty == true)

        let ranges = schedule.availablePeriods(on: schedule.date, now: previousDay)!
            .compactMap { $0.selectableRange(on: schedule.date, now: previousDay) }
        let tenTwentyFour = ten.startDate(on: schedule.date)!.addingTimeInterval(24 * 60)
        assert(BookingTimeSelection.nearest(to: tenTwentyFour, in: ranges) == tenTwentyFour)
        let blocked = periods[2].startDate(on: schedule.date)!
        let corrected = BookingTimeSelection.nearest(to: blocked, in: ranges)!
        assert(ranges.contains { $0.contains(corrected) })
        assert(corrected != blocked)
        assert(BookingTimeSelection.nearest(to: blocked, in: []) == nil)
        let remaining = schedule.availablePeriods(on: schedule.date, now: currentTime)!
            .compactMap { $0.selectableRange(on: schedule.date, now: currentTime) }
        assert(BookingTimeSelection.nearest(to: ten.startDate(on: schedule.date)!, in: remaining) == tenTwentyFour)

        let clock = BookingClockSelection(day: previousDay.addingTimeInterval(86400), ranges: ranges)
        assert(clock.hours.count == 21)
        assert(!clock.hours.contains(1) && !clock.hours.contains(2) && !clock.hours.contains(3))
        assert(clock.minutes(for: 10).contains(24))
        assert(clock.minutes(for: 1).isEmpty)
        let liveClock = BookingClockSelection(day: currentTime, ranges: remaining)
        assert(!liveClock.minutes(for: 10).contains(23))
        assert(liveClock.minutes(for: 10).first == 24)
        assert(clock.minutes(for: 23).last == 59)
        assert(clock.date(hour: 24, minute: 0) == nil)

        let scheduleData = try JSONEncoder().encode(schedule)
        let scheduleJSON = String(data: scheduleData, encoding: .utf8)!
        let responseJSON = """
        {"key":"success","msg":"","user_status":"","data":{"delegate":{
          "id":166,"day_periods":\(scheduleJSON),"commercial_file":"https://example.com/file.pdf",
          "services":[{"id":251,"price":"30.00","can_edit_delete":false}],
          "works":[{"id":164,"category_id":2,"category_name":"سباكة"}]
        }}}
        """
        let response = try JSONDecoder().decode(BaseResponse<ProviderDetailsResponse>.self, from: Data(responseJSON.utf8))
        let provider = response.data!.delegate!
        assert(provider.dayPeriods?.periods.count == 24)
        assert(provider.services?.first?.canEditDelete == false)
        assert(provider.services?.first?.quantity == 1)
        assert(provider.works?.first?.categoryId == 2)
        let context = OrderContext(categoryId: 2, subCategoryId: 73, delegateId: 166, services: [], dayPeriods: provider.dayPeriods)
        let restored = try JSONDecoder().decode(OrderContext.self, from: JSONEncoder().encode(context))
        assert(restored.dayPeriods?.periods == periods)
        let oldProvider = try JSONDecoder().decode(DelegateModel.self, from: Data(#"{"id":166}"#.utf8))
        assert(oldProvider.dayPeriods == nil)
        print("Provider response, booking context, closed hours, date scoping, midnight and minute-selection checks passed")
    }
}
