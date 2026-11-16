//
//  OrderSummaryVM.swift
//  Profix
//
//  Created by Haneen on 15/01/2026.
//


import Foundation
import Combine

protocol OrderSummaryVMProtocol {
    
    var createOrderPublisher: Published<BaseResponse<CreateOrderResponse>?>.Publisher { get }
    var orderEnquiryPublisher: Published<BaseResponse<OrderEnquiryResponse>?>.Publisher { get }
    var validationPublisher: Published<ValidationError?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var orderModel : CreateOrderModel { get set }
    var servicesList : [Services] { get }
    
    func orderEnquiryRequest()
    func createOrderRequest()
    func getProblemDescImages() -> [ProblemDescImageType]
}

final class OrderSummaryVM : BaseViewModel , OrderSummaryVMProtocol {
    
    @Published var orderEnquiry: BaseResponse<OrderEnquiryResponse>?
    @Published var createOrder: BaseResponse<CreateOrderResponse>?
    @Published var validation: ValidationError?
    
    var orderEnquiryPublisher: Published<BaseResponse<OrderEnquiryResponse>?>.Publisher { $orderEnquiry}
    var createOrderPublisher: Published<BaseResponse<CreateOrderResponse>?>.Publisher { $createOrder }
    var validationPublisher: Published<ValidationError?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var orderModel : CreateOrderModel
    var servicesList : [Services] = []
    private let analytics: OrderAnalytics
    
    init(orderModel: CreateOrderModel, analytics: OrderAnalytics = .shared) {
        self.orderModel = orderModel
        self.analytics = analytics
        super.init()
    }
    
    func createOrderRequest(){
        isLoading = true
        Task { @MainActor in
            do {
                let result = try await getAllRequest(HomeEndPoints.createOrder(model: orderModel))
                if result.key == .success, let orderId = result.data?.orderId {
                    analytics.orderCreated(orderId: orderId)
                }
                isLoading = false
                createOrder = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func orderEnquiryRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(
                    HomeEndPoints.orderEnquiryRequest(
                        coupon: orderModel.coupon,
                        services: orderModel.services ?? []
                    )
                )
                isLoading = false
                servicesList = result.data?.services ?? []
                orderEnquiry = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func getProblemDescImages() -> [ProblemDescImageType]{
        return orderModel.images.map {
            .local($0)
        }
    }

}
