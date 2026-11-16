//
//  PaymentMethods.swift
//  Profix
//
//  Created by Haneen on 18/01/2026.
//

import Foundation


struct PaymentMethodsResponse : Codable {
    let paymentMethod : [PaymentMethodModel]?
    
    enum CodingKeys : String,CodingKey {
        case paymentMethod = "payment_methods"
    }
}

struct PaymentMethodModel : Codable {
    let id : Int?
    let key : String?
    let name : String?
    let desc : String?
    let image : String?
    var isSelected : Bool = false
    
    enum CodingKeys : String,CodingKey {
        case id,key,name,desc,image
    }
}

enum PaymentNavigationType {
    case order
    case invoice
}

struct PayOrderResponse: Decodable {
    let amount: String?
    let cartId: String?
    let currency: String?
    let gatewayResponse: PaymentGatewayResponse?
    let orderRef: String?
    let paymentUrl: String?
    let testMode: String?
    let transactionId: Int?
    let type: String?

    var checkoutURL: String? {
        [paymentUrl, gatewayResponse?.order?.url]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case amount, currency, type
        case cartId = "cart_id"
        case gatewayResponse = "gateway_response"
        case orderRef = "order_ref"
        case paymentUrl = "payment_url"
        case testMode = "test_mode"
        case transactionId = "transaction_id"
    }
}

// Keep the request's order and method with its response through online checkout.
struct OrderPaymentResult {
    let response: BaseResponse<PayOrderResponse>
    let context: OrderPaymentContext
}

struct PaymentGatewayResponse: Decodable {
    let method: String?
    let order: PaymentGatewayOrder?
    let trace: String?
}

struct PaymentGatewayOrder: Decodable {
    let ref: String?
    let url: String?
}
