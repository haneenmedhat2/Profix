import Foundation
import Combine

// Compile the production ViewModel against lightweight network/model fixtures.
// This exercises its real Combine timer and refresh lifecycle without backend writes.
struct Endpoint<T> {
    var action = "details"
    var orderId: Int?
    var paymentMethod: String?
}
struct OrderDetailsResponse: Codable { let order: OrderDetailsModel }
enum OrderStatus: String, Codable { case open, accepted, closed }
struct OrderDetailsModel: Codable {
    let paymentTimeoutTimer: Int?
    let paymentTimeoutMessage: String?
    var status: OrderStatus? = .accepted
    var acceptTimeoutClock: String? = nil
    var acceptTimeoutHours: Int? = nil
    var acceptTimeoutMessage: String? = nil
    var acceptTimeoutMinutes: Int? = nil
    var acceptTimeoutSeconds: Int? = nil
    var acceptTimeoutTimer: Int? = nil
}
struct EmptyModel: Codable {}
typealias AddComplaintsResponse = EmptyModel
typealias CustomerReviewModel = EmptyModel
typealias PledgeResponse = EmptyModel
typealias CancelReasonsModel = EmptyModel
struct Reasons: Codable { let reasons: [CancelReasonsModel]? }
struct Methods: Codable { let paymentMethod: [PaymentMethodModel]? }
enum OrderReasonSelectionType { case cancelOrder }
enum OrderDetailsEndPoints {
    static func getOrderDetials(orderId: Int) -> Endpoint<BaseResponse<OrderDetailsResponse>> { .init() }
    static func getCancelReasons() -> Endpoint<BaseResponse<Reasons>> { .init() }
    static func cancelOrder(orderId: Int, cancelReason: String) -> Endpoint<BaseResponse<String>> { .init() }
    static func getPaymentMethods() -> Endpoint<BaseResponse<Methods>> { .init() }
    static func payOrder(orderId: Int, paymentType: String) -> Endpoint<BaseResponse<PayOrderResponse>> {
        .init(action: "pay", orderId: orderId, paymentMethod: paymentType)
    }
    static func acceptInvoice(orderId: Int, paymentMethod: String) -> Endpoint<BaseResponse<PayOrderResponse>> {
        .init(action: "invoice", orderId: orderId, paymentMethod: paymentMethod)
    }
    static func rejectInvoice(orderId: Int, reason: String) -> Endpoint<BaseResponse<String>> { .init() }
    static func acceptPledge(orderId: Int) -> Endpoint<BaseResponse<PledgeResponse>> { .init() }
}
enum HomeEndPoints {
    static func createProviderReview(model: CustomerReviewModel) -> Endpoint<BaseResponse<String>> { .init() }
    static func createOrder(model: CreateOrderModel) -> Endpoint<BaseResponse<CreateOrderResponse>> {
        .init(action: "create")
    }
    static func orderEnquiryRequest(coupon: String?, services: [SelectedService]) -> Endpoint<BaseResponse<OrderEnquiryResponse>> { .init() }
}
struct SelectedService: Codable { let serviceId: Int; let quantity: Int }
struct Services: Codable {}
struct OrderEnquiryResponse: Codable { let services: [Services] }
enum ValidationError: Error {}
extension OrderAnalytics {
    static let shared = OrderAnalytics { _, _ in
        assertionFailure("Analytics checks must inject their event recorder")
    }
}
class BaseViewModel: NSObject {
    @Published var isLoading = false
    @Published var error: Error?
    static var responses: [(Int?, UInt64)] = []
    static var orderOverride: OrderDetailsModel?
    static var calls = 0
    static var inFlight = 0
    static var peakInFlight = 0
    static var actionResponses: [String: Result<Data, Error>] = [:]
    static var actions: [(name: String, orderId: Int?, method: String?)] = []
    func getAllRequest<T>(_ endpoint: Endpoint<BaseResponse<T>>) async throws -> BaseResponse<T> {
        if let response = Self.actionResponses[endpoint.action] {
            Self.actions.append((endpoint.action, endpoint.orderId, endpoint.paymentMethod))
            try await Task.sleep(nanoseconds: 10_000_000)
            return try JSONDecoder().decode(BaseResponse<T>.self, from: response.get())
        }
        Self.calls += 1
        Self.inFlight += 1
        Self.peakInFlight = max(Self.peakInFlight, Self.inFlight)
        defer { Self.inFlight -= 1 }
        let item = Self.responses.isEmpty ? (nil, UInt64(0)) : Self.responses.removeFirst()
        if item.1 > 0 { try await Task.sleep(nanoseconds: item.1) }
        let data = OrderDetailsResponse(order: Self.orderOverride ?? .init(paymentTimeoutTimer: item.0, paymentTimeoutMessage: "API message"))
        return BaseResponse(key: .success, message: "", data: data, userStatus: nil) as! BaseResponse<T>
    }
}
@main struct Checks {
    static func pump(_ seconds: Double) { RunLoop.main.run(until: Date().addingTimeInterval(seconds)) }
    static func main() {
        let vm = OrderDetailsVM(orderId: 394)
        var state: PaymentCountdownState?
        let subscription = vm.paymentCountdownPublisher.sink { state = $0 }
        BaseViewModel.responses = [(2, 0), (0, 0)]
        vm.resumePaymentCountdown()
        pump(0.1)
        assert(state?.remainingSeconds == 2 && state?.message == "API message")
        vm.resumePaymentCountdown()
        pump(2.2)
        assert(state == nil && BaseViewModel.calls == 2, "Expiry refreshes exactly once; resume is idempotent")
        pump(1.1)
        assert(BaseViewModel.calls == 2)
        BaseViewModel.responses = [(20, 0)]
        vm.getOrderDetails()
        pump(0.1)
        assert(state?.remainingSeconds == 20)
        vm.stopPaymentCountdown()
        assert(state == nil)
        BaseViewModel.responses = [(10, 0)]
        vm.getOrderDetails()
        pump(0.1)
        assert(state == nil, "Offscreen responses must not restart the timer")
        BaseViewModel.responses = [(30, 300_000_000), (5, 0)]
        vm.resumePaymentCountdown()
        pump(0.1)
        vm.getOrderDetails()
        vm.getOrderDetails()
        pump(0.4)
        assert(state?.remainingSeconds == 5)
        assert(BaseViewModel.peakInFlight == 1, "Refresh requests must be serialized")
        BaseViewModel.responses = [(-1, 0)]
        vm.getOrderDetails()
        pump(0.1)
        assert(state == nil)
        vm.stopPaymentCountdown()
        var acceptance: PaymentCountdownState?
        let acceptanceSubscription = vm.acceptanceCountdownPublisher.sink { acceptance = $0 }
        BaseViewModel.orderOverride = .init(paymentTimeoutTimer: 50, paymentTimeoutMessage: "Payment", status: .open, acceptTimeoutMessage: "Accept soon", acceptTimeoutTimer: 2)
        vm.resumePaymentCountdown()
        pump(0.1)
        assert(acceptance?.remainingSeconds == 2 && acceptance?.message == "Accept soon")
        assert(state == nil, "Open orders show acceptance rather than payment countdown")
        let callsBeforeExpiry = BaseViewModel.calls
        BaseViewModel.orderOverride?.acceptTimeoutTimer = 0
        pump(2.2)
        assert(acceptance?.remainingSeconds == 0 && BaseViewModel.calls == callsBeforeExpiry + 1)
        pump(1.1)
        assert(BaseViewModel.calls == callsBeforeExpiry + 1, "Zero must not create a refresh loop")
        BaseViewModel.orderOverride?.status = .accepted
        vm.getOrderDetails()
        pump(0.1)
        assert(acceptance == nil && state?.remainingSeconds == 50)
        BaseViewModel.orderOverride?.status = .open
        BaseViewModel.orderOverride?.acceptTimeoutTimer = 10
        vm.getOrderDetails()
        pump(0.1)
        vm.stopPaymentCountdown()
        assert(acceptance == nil)
        vm.getOrderDetails()
        pump(0.1)
        assert(acceptance == nil, "Offscreen acceptance response must not restart timer")
        BaseViewModel.orderOverride = nil
        acceptanceSubscription.cancel()
        subscription.cancel()
        weak var released: OrderDetailsVM?
        do {
            let temporary = OrderDetailsVM(orderId: 1)
            released = temporary
            BaseViewModel.responses = [(10, 0)]
            temporary.resumePaymentCountdown()
            pump(0.1)
        }
        assert(released == nil, "Timer must not retain its ViewModel")
        print("ViewModel lifecycle, expiry, reconciliation, request serialization and deallocation checks passed")
        checkOrderAnalytics()
    }
}
