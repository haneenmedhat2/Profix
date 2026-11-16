import Foundation

// Standalone checks against production sources; no backend or simulator required.
@main
enum UserAppContractChecks {
    static func main() throws {
        let cases = [(0, "00:00:00"), (-1, "00:00:00"), (1, "00:00:01"),
                     (59, "00:00:59"), (60, "00:01:00"), (287, "00:04:47"),
                     (3588, "00:59:48"), (3600, "01:00:00"), (90061, "25:01:01")]
        for (seconds, expected) in cases {
            assert(PaymentCountdownState(remainingSeconds: seconds, message: "").clock == expected)
        }

        assert(AcceptanceCountdown.seconds(timer: 0, hours: 1, minutes: 2, seconds: 3, clock: "01:02:03") == 0)
        assert(AcceptanceCountdown.seconds(timer: 90, hours: nil, minutes: nil, seconds: nil, clock: nil) == 90)
        assert(AcceptanceCountdown.seconds(timer: nil, hours: 1, minutes: 2, seconds: 3, clock: nil) == 3723)
        assert(AcceptanceCountdown.seconds(timer: nil, hours: nil, minutes: nil, seconds: nil, clock: "01:02:03") == 3723)
        assert(AcceptanceCountdown.seconds(timer: nil, hours: nil, minutes: nil, seconds: nil, clock: "invalid") == nil)
        assert(AcceptanceCountdown.seconds(timer: nil, hours: nil, minutes: nil, seconds: nil, clock: nil) == nil)
        let deadline = PaymentCountdownDeadline(seconds: 5, now: 100)
        assert(deadline.remainingSeconds(now: 100) == 5)
        assert(deadline.remainingSeconds(now: 100.5) == 5)
        assert(deadline.remainingSeconds(now: 101) == 4)
        // Delayed ticks must account for all elapsed time.
        assert(deadline.remainingSeconds(now: 104.2) == 1)
        assert(deadline.remainingSeconds(now: 105) == 0)
        assert(deadline.remainingSeconds(now: 200) == 0)
        assert(PaymentCountdownDeadline(seconds: -10, now: 100).remainingSeconds(now: 100) == 0)

        struct CreatedOrder: Decodable {
            let order_id: Int
        }
        let message = "  تم تأكيد الطلب بانتظار قبول مقدم الخدمة.  "
        for value in [nil, NSNull(), "", " \n ", message] as [Any?] {
            var object: [String: Any] = ["key": "success", "data": ["order_id": 394]]
            if let value { object["msg"] = value }
            let json = try JSONSerialization.data(withJSONObject: object)
            let response = try JSONDecoder().decode(BaseResponse<CreatedOrder>.self, from: json)
            assert(response.message == (value as? String ?? ""))
            assert(response.data?.order_id == 394)
        }
        // Invalid message types remain decoding errors, rather than hiding contract failures.
        let invalid = Data(#"{"key":"success","msg":42}"#.utf8)
        do {
            _ = try JSONDecoder().decode(BaseResponse<CreatedOrder>.self, from: invalid)
            assertionFailure("Expected invalid message type to fail decoding")
        } catch is DecodingError { }
        print("UserApp countdown and response contract checks passed")
    }
}
