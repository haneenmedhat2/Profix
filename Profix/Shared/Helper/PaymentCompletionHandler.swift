import Foundation

final class PaymentCompletionHandler {
    enum Outcome {
        case success
        case failure
    }

    private let checkoutURL: URL?
    private let orderPayment: OrderPaymentContext?
    private let analytics: OrderAnalytics
    private(set) var isComplete = false

    init(checkoutURL: String?, orderPayment: OrderPaymentContext?, analytics: OrderAnalytics = .shared) {
        self.checkoutURL = checkoutURL.flatMap(URL.init(string:))
        self.orderPayment = orderPayment
        self.analytics = analytics
    }

    func handleRedirect(_ url: URL) -> Outcome? {
        // Checkout URLs can themselves contain callback URLs or "success".
        guard !isComplete, url != checkoutURL else { return nil }
        let redirect = url.absoluteString.lowercased()
        if redirect.contains("error") || redirect.contains("failed") {
            isComplete = true
            return .failure
        }
        guard redirect.contains("success") else { return nil }

        isComplete = true
        if let orderPayment {
            analytics.orderPaid(orderPayment)
        }
        return .success
    }

    func cancel() {
        isComplete = true
    }
}
