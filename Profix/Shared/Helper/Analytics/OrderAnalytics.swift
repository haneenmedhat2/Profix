import Foundation

enum AnalyticsEvent {
    static let orderCreated = "order_created"
    static let orderPaid = "order_paid"
}

enum AnalyticsParameter {
    static let orderId = "order_id"
    static let paymentMethod = "payment_method"
}

struct OrderPaymentContext {
    let orderId: Int
    let paymentMethod: String?
}

final class OrderAnalytics {
    private let logEvent: (String, [String: Any]) -> Void

    init(logEvent: @escaping (String, [String: Any]) -> Void) {
        self.logEvent = logEvent
    }

    func orderCreated(orderId: Int) {
        logEvent(AnalyticsEvent.orderCreated, [AnalyticsParameter.orderId: orderId])
    }

    func orderPaid(_ payment: OrderPaymentContext) {
        var parameters: [String: Any] = [AnalyticsParameter.orderId: payment.orderId]
        if let method = payment.paymentMethod,
           !method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parameters[AnalyticsParameter.paymentMethod] = method
        }
        logEvent(AnalyticsEvent.orderPaid, parameters)
    }
}
