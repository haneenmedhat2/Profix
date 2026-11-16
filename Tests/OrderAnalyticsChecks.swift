import Foundation
import Combine

extension Checks {
    static func checkOrderAnalytics() {
        var events: [(name: String, parameters: [String: Any])] = []
        let analytics = OrderAnalytics { events.append(($0, $1)) }
        func response(_ action: String, _ json: String) {
            BaseViewModel.actionResponses[action] = .success(Data(json.utf8))
        }
        func expectEvent(_ name: String, orderId: Int, method: String? = nil) {
            assert(events.count == 1, "Expected exactly one \(name), got \(events.count)")
            assert(events[0].name == name)
            assert(events[0].parameters["order_id"] as? Int == orderId)
            assert(events[0].parameters["payment_method"] as? String == method)
            assert(events[0].parameters.count == (method == nil ? 1 : 2))
            events.removeAll()
        }

        let summary = OrderSummaryVM(orderModel: CreateOrderModel(), analytics: analytics)
        response("create", #"{"key":"success","data":{"order_id":394}}"#)
        summary.createOrderRequest()
        assert(events.isEmpty, "Starting a request must not emit an event")
        pump(0.1)
        expectEvent("order_created", orderId: 394)
        let creationSubscription = summary.createOrderPublisher.sink { _ in }
        assert(events.isEmpty, "Replaying the response to a subscriber must not log again")
        creationSubscription.cancel()

        for json in [
            #"{"key":"fail","data":{"order_id":394}}"#,
            #"{"key":"needApproval","data":{"order_id":394}}"#,
            #"{"key":"success","data":null}"#,
            #"{"key":"success","data":{}}"#
        ] {
            response("create", json)
            summary.createOrderRequest()
            pump(0.1)
            assert(events.isEmpty, "Only success with a backend order ID may be logged")
        }
        BaseViewModel.actionResponses["create"] = .failure(URLError(.cancelled))
        summary.createOrderRequest()
        pump(0.1)
        assert(events.isEmpty)

        let details = OrderDetailsVM(orderId: 394, analytics: analytics)
        for action in ["pay", "invoice"] {
            func request(_ method: String = "wallet") {
                if action == "pay" {
                    details.payOrderrequest(paymentType: method)
                } else {
                    details.acceptInvoice(paymentMethod: method)
                }
            }
            for data in ["{}", "null", #"{"payment_url":""}"#] {
                response(action, #"{"key":"success","data":\#(data)}"#)
                request()
                assert(events.isEmpty)
                pump(0.1)
                expectEvent("order_paid", orderId: 394, method: "wallet")
            }

            for key in ["fail", "exception", "blocked", "unauthenticated", "needApproval", "needActive"] {
                response(action, #"{"key":"\#(key)","data":{}}"#)
                request()
                pump(0.1)
                assert(events.isEmpty, "Unsuccessful \(action) must not log payment")
            }
            BaseViewModel.actionResponses[action] = .failure(URLError(.cancelled))
            request()
            pump(0.1)
            assert(events.isEmpty, "Cancelled requests must not log payment")

            for data in [
                #"{"payment_url":"https://gateway.example/checkout"}"#,
                #"{"gateway_response":{"order":{"url":"https://gateway.example/checkout"}}}"#,
                #"{"payment_url":" ","gateway_response":{"order":{"url":"https://gateway.example/checkout"}}}"#
            ] {
                response(action, #"{"key":"success","data":\#(data)}"#)
                request("card")
                // The response must retain the order ID used by this request.
                details.orderId = 999
                pump(0.1)
                assert(events.isEmpty, "Opening online checkout must not log payment")
                let result = (action == "pay" ? details.payOrder : details.acceptInvoice)!
                assert(result.context.orderId == 394 && result.context.paymentMethod == "card")
                assert(BaseViewModel.actions.last?.orderId == 394)
                assert(BaseViewModel.actions.last?.method == "card")
                assert(result.response.data?.checkoutURL == "https://gateway.example/checkout")
                let completion = PaymentCompletionHandler(
                    checkoutURL: result.response.data?.checkoutURL,
                    orderPayment: result.context,
                    analytics: analytics
                )
                assert(completion.handleRedirect(URL(string: result.response.data!.checkoutURL!)!) == nil)
                assert(events.isEmpty)
                assert(completion.handleRedirect(URL(string: "https://backend.example/payment/SuCcEsS")!) == .success)
                expectEvent("order_paid", orderId: 394, method: "card")
                assert(completion.handleRedirect(URL(string: "https://backend.example/payment/success")!) == nil)
                assert(events.isEmpty, "Repeated WebView callbacks must not log again")
                details.orderId = 394
            }
        }

        let context = OrderPaymentContext(orderId: 401, paymentMethod: nil)
        func checkout(order: OrderPaymentContext? = context) -> PaymentCompletionHandler {
            PaymentCompletionHandler(
                checkoutURL: "https://gateway.example/checkout?success_url=https://backend.example/success",
                orderPayment: order,
                analytics: analytics
            )
        }
        let initial = checkout()
        assert(initial.handleRedirect(URL(string: "https://gateway.example/checkout?success_url=https://backend.example/success")!) == nil)
        for path in ["/api/telr/callback?status=A", "/orders/accepted-form", "/payment/get-payment-status"] {
            assert(initial.handleRedirect(URL(string: "https://backend.example\(path)")!) == nil)
        }
        assert(events.isEmpty, "Checkout and intermediate callbacks are not success")
        assert(initial.handleRedirect(URL(string: "https://backend.example/success")!) == .success)
        expectEvent("order_paid", orderId: 401)

        for path in ["/ERROR", "/FaIlEd", "/success?error=declined", "/success?failed=true"] {
            let failed = checkout()
            assert(failed.handleRedirect(URL(string: "https://backend.example\(path)")!) == .failure)
            assert(failed.handleRedirect(URL(string: "https://backend.example/success")!) == nil)
            assert(events.isEmpty, "Failures take priority and are terminal")
        }
        let cancelled = checkout()
        cancelled.cancel()
        assert(cancelled.handleRedirect(URL(string: "https://backend.example/success")!) == nil)
        assert(events.isEmpty, "Closing checkout must not log payment")

        let walletRecharge = checkout(order: nil)
        assert(walletRecharge.handleRedirect(URL(string: "https://backend.example/success")!) == .success)
        assert(events.isEmpty, "Wallet recharge has no order context and must not log payment")

        analytics.orderPaid(OrderPaymentContext(orderId: 402, paymentMethod: " "))
        expectEvent("order_paid", orderId: 402)
        print("Order creation, wallet/invoice payments, online redirects, deduplication, cancellation and wallet recharge analytics checks passed")
    }
}
