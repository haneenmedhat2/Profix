//
//  ReservationDetailsEndPoints.swift
//  Waraqa
//
//  Created by Haneen on 21/09/2025.
//

import Foundation
import Alamofire

struct OrderDetailsEndPoints {
    private init() {}
}

extension OrderDetailsEndPoints {
    
    static func getOrderDetials(orderId : Int) -> Endpoint<BaseResponse<OrderDetailsResponse>>{
        return .init(
            method: .get,
            path: "user-single-order",
            queries: [
                "order_id" : orderId
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func getCancelReasons() -> Endpoint<BaseResponse<CancelReasonsResponse>>{
        return .init(
            method: .get,
            path: "cancel-reasons",
            queries: [
                "user_type" : "user"
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func cancelOrder(orderId : Int,cancelReason: String ) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "cancel-order",
            body: [
                "order_id" : orderId,
                "reason" : cancelReason
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func getPaymentMethods() -> Endpoint<BaseResponse<PaymentMethodsResponse>>{
        return .init(
            method: .get,
            path: "payment-methods"
        )
    }
    
    static func payOrder(orderId : Int,paymentType: String ) -> Endpoint<BaseResponse<PayOrderResponse>>{
        return .init(
            method: .post,
            path: "pay-order",
            body: [
                "order_id" : orderId,
                "payment_type" : paymentType
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func updateDate(orderId : Int, date: String , time: String) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "user-update-date",
            body: [
                "order_id" : orderId,
                "date" : date,
                "time" : time
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func acceptInvoice(orderId : Int, paymentMethod :String) -> Endpoint<BaseResponse<PayOrderResponse>>{
        return .init(
            method: .post,
            path: "user-accept-invoice",
            body: [
                "order_id" : orderId,
                "payment_method" : paymentMethod,
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func rejectInvoice(orderId : Int, reason :String) -> Endpoint<BaseResponse<String>>{
        return .init(
            method: .post,
            path: "user-reject-invoice",
            body: [
                "order_id" : orderId,
                "reason" : reason,
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }

    static func acceptPledge(orderId: Int) -> Endpoint<BaseResponse<PledgeResponse>>{
        return .init(
            method: .post,
            path: "pledge",
            body: [
                "order_id": orderId
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
}
