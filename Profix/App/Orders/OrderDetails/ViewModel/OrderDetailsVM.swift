//
//  OrderDetailsVM.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import Foundation
import Combine

protocol OrderDetailsVMProtocol {
    
    var orderDetailsPublisher: Published<BaseResponse<OrderDetailsResponse>?>.Publisher  { get }
    var addNewComplaintPublisher: Published<BaseResponse<AddComplaintsResponse>?>.Publisher { get }
    var cancelOrderPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var confirmOrderPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var rejectOrderPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var rateOrderPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var paymentMethodsPublisher: Published<[PaymentMethodModel]>.Publisher { get }
    var cancelReasonsPublisher: Published<[CancelReasonsModel]>.Publisher { get }
    var payOrderPublisher: Published<OrderPaymentResult?>.Publisher { get }
    var reviewPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var acceptInvoicePublisher: Published<OrderPaymentResult?>.Publisher { get }
    var rejectInvoicePublisher: Published<BaseResponse<String>?>.Publisher { get }
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }

    var paymentCountdownPublisher: Published<PaymentCountdownState?>.Publisher { get }
    var acceptanceCountdownPublisher: Published<PaymentCountdownState?>.Publisher { get }

    var orderId : Int { get }
    var orderDetailsModel : OrderDetailsModel? { get }
    var paymentNavType : PaymentNavigationType { get set }
    var orderReasonType : OrderReasonSelectionType { get set }

     func resumePaymentCountdown()
     func stopPaymentCountdown()
     func getOrderDetails()
     func getCancelOrderReasons()
     func cancelOrder(reason: String)
     func getPaymentMethods()
     func payOrderrequest(paymentType: String)
     func createReview(model : CustomerReviewModel)
     func acceptInvoice(paymentMethod : String)
     func rejectInvoice(reason: String)
     func acceptPledge()
}

final class OrderDetailsVM: BaseViewModel,OrderDetailsVMProtocol {
    @Published private var acceptanceCountdown: PaymentCountdownState?
    var acceptanceCountdownPublisher: Published<PaymentCountdownState?>.Publisher { $acceptanceCountdown }
    @Published private var paymentCountdown: PaymentCountdownState?
    var paymentCountdownPublisher: Published<PaymentCountdownState?>.Publisher { $paymentCountdown }
    private var countdownSubscription: AnyCancellable?
    private var countdownDeadline: PaymentCountdownDeadline?
    private var isCountdownActive = false
    private var isFetchingOrder = false
    private var needsOrderRefresh = false
    private let analytics: OrderAnalytics

    @Published var orderDetails : BaseResponse<OrderDetailsResponse>?
    @Published var addNewComplaint: BaseResponse<AddComplaintsResponse>?
    @Published var cancelOrder: BaseResponse<String>?
    @Published var confirmOrder: BaseResponse<String>?
    @Published var rejectOrder: BaseResponse<String>?
    @Published var rateOrder: BaseResponse<String>?
    @Published var payOrder: OrderPaymentResult?
    @Published var cancelReasonList : [CancelReasonsModel] = []
    @Published var paymentMethodList : [PaymentMethodModel] = []
    @Published var review : BaseResponse<String>?
    @Published var acceptInvoice : OrderPaymentResult?
    @Published var rejectInvoice : BaseResponse<String>?

    var orderDetailsPublisher: Published<BaseResponse<OrderDetailsResponse>?>.Publisher  { $orderDetails }
    var addNewComplaintPublisher: Published<BaseResponse<AddComplaintsResponse>?>.Publisher { $addNewComplaint }
    var cancelOrderPublisher: Published<BaseResponse<String>?>.Publisher { $cancelOrder }
    var confirmOrderPublisher: Published<BaseResponse<String>?>.Publisher { $confirmOrder }
    var rejectOrderPublisher: Published<BaseResponse<String>?>.Publisher { $rejectOrder }
    var rateOrderPublisher: Published<BaseResponse<String>?>.Publisher { $rateOrder }
    var cancelReasonsPublisher: Published<[CancelReasonsModel]>.Publisher { $cancelReasonList }
    var paymentMethodsPublisher: Published<[PaymentMethodModel]>.Publisher { $paymentMethodList }
    var payOrderPublisher: Published<OrderPaymentResult?>.Publisher { $payOrder }
    var reviewPublisher: Published<BaseResponse<String>?>.Publisher { $review }
    var acceptInvoicePublisher: Published<OrderPaymentResult?>.Publisher { $acceptInvoice }
    var rejectInvoicePublisher: Published<BaseResponse<String>?>.Publisher { $rejectInvoice }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
        
    var orderId : Int
    var orderDetailsModel : OrderDetailsModel?
    var paymentNavType : PaymentNavigationType = .order
    var orderReasonType : OrderReasonSelectionType = .cancelOrder


    init(orderId: Int, analytics: OrderAnalytics = .shared) {
        self.orderId = orderId
        self.analytics = analytics
        super.init()
    }

    func getOrderDetails() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard !isFetchingOrder else {
                needsOrderRefresh = true
                return
            }
            isFetchingOrder = true
            isLoading = true
            defer {
                isFetchingOrder = false
                isLoading = false
            }
            repeat {
                needsOrderRefresh = false
                do {
                    let result = try await getAllRequest(OrderDetailsEndPoints.getOrderDetials(orderId: orderId))
                    // A newer refresh trigger arrived while this request was in flight.
                    guard !needsOrderRefresh else { continue }
                    orderDetailsModel = result.data?.order
                    orderDetails = result
                    reconcilePaymentCountdown()
                } catch {
                    if !needsOrderRefresh { self.error = error }
                }
            } while needsOrderRefresh
        }
    }

    func resumePaymentCountdown() {
        guard !isCountdownActive else { return }
        isCountdownActive = true
        getOrderDetails()
    }

    func stopPaymentCountdown() {
        isCountdownActive = false
        clearPaymentCountdown()
    }

    private func clearPaymentCountdown() {
        countdownSubscription?.cancel()
        countdownSubscription = nil
        countdownDeadline = nil
        paymentCountdown = nil
        acceptanceCountdown = nil
    }

    private func reconcilePaymentCountdown() {
        clearPaymentCountdown()
        guard isCountdownActive else { return }
        if let order = orderDetailsModel, order.status == .open {
            guard let seconds = AcceptanceCountdown.seconds(
                timer: order.acceptTimeoutTimer, hours: order.acceptTimeoutHours,
                minutes: order.acceptTimeoutMinutes, seconds: order.acceptTimeoutSeconds,
                clock: order.acceptTimeoutClock
            ) else { return }
            acceptanceCountdown = PaymentCountdownState(remainingSeconds: seconds, message: order.acceptTimeoutMessage ?? "")
            guard seconds > 0 else { return }
            countdownDeadline = PaymentCountdownDeadline(seconds: seconds)
            countdownSubscription = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.tickPaymentCountdown() }
            return
        }
        guard isCountdownActive,
              let seconds = orderDetailsModel?.paymentTimeoutTimer,
              seconds > 0 else { return }
        countdownDeadline = PaymentCountdownDeadline(seconds: seconds)
        paymentCountdown = PaymentCountdownState(
            remainingSeconds: seconds,
            message: orderDetailsModel?.paymentTimeoutMessage ?? ""
        )
        countdownSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tickPaymentCountdown() }
    }

    private func tickPaymentCountdown() {
        guard isCountdownActive, let deadline = countdownDeadline else { return }
        let remaining = deadline.remainingSeconds()
        if let state = acceptanceCountdown {
            acceptanceCountdown = PaymentCountdownState(remainingSeconds: remaining, message: state.message)
            if remaining == 0 {
                countdownSubscription?.cancel()
                countdownSubscription = nil
                countdownDeadline = nil
                getOrderDetails()
            }
            return
        }
        guard remaining > 0 else {
            clearPaymentCountdown()
            getOrderDetails()
            return
        }
        paymentCountdown = PaymentCountdownState(
            remainingSeconds: remaining,
            message: paymentCountdown?.message ?? ""
        )
    }

    deinit {
        countdownSubscription?.cancel()
    }

    func getCancelOrderReasons(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.getCancelReasons())
                cancelReasonList = result.data?.reasons ?? []
                isLoading = false
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
        func cancelOrder(reason: String){
            isLoading = true
            Task {
                do {
                    let result = try await getAllRequest(OrderDetailsEndPoints.cancelOrder(orderId: orderId, cancelReason: reason))
                    cancelOrder = result
                    isLoading = false
    
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        }
    
    func getPaymentMethods(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.getPaymentMethods())
                paymentMethodList = result.data?.paymentMethod ?? []
                isLoading = false

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func payOrderrequest(paymentType: String){
        let context = OrderPaymentContext(orderId: orderId, paymentMethod: paymentType)
        isLoading = true
        Task { @MainActor in
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.payOrder(orderId: context.orderId, paymentType: paymentType))
                if result.key == .success {
                    if result.data?.checkoutURL == nil {
                        analytics.orderPaid(context)
                    }
                    payOrder = OrderPaymentResult(response: result, context: context)
                }
                isLoading = false

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func createReview(model : CustomerReviewModel){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.createProviderReview(model: model))
                getOrderDetails()
                isLoading = false
                review = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func acceptInvoice(paymentMethod : String){
        let context = OrderPaymentContext(orderId: orderId, paymentMethod: paymentMethod)
        isLoading = true
        Task { @MainActor in
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.acceptInvoice(orderId: context.orderId, paymentMethod: paymentMethod))
                if result.key == .success {
                    if result.data?.checkoutURL == nil {
                        analytics.orderPaid(context)
                    }
                    acceptInvoice = OrderPaymentResult(response: result, context: context)
                }
                getOrderDetails()
                isLoading = false
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func rejectInvoice(reason: String){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.rejectInvoice(orderId: orderId, reason: reason))
                getOrderDetails()
                isLoading = false
                rejectInvoice = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    func acceptPledge(){
        isLoading = true
        Task {
            do {
                let _: BaseResponse<PledgeResponse> = try await getAllRequest(
                    OrderDetailsEndPoints.acceptPledge(orderId: orderId)
                )
                isLoading = false
                getOrderDetails()

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
