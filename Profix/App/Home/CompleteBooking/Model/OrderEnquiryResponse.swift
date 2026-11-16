//
//  CreateOrderModel.swift
//  Profix
//
//  Created by Haneen on 11/01/2026.
//

import Foundation
import UIKit

struct OrderEnquiryResponse : Codable {
    
    var price : String?
    var appPercentage : String?
    var addedValue : String?
    var discount : Int?
    var totalPrice : String?
    var hasCoupon : Bool?
    var couponMsg : String?
    var services : [Services]
    
    enum CodingKeys: String, CodingKey {
        case price
        case appPercentage = "app_percentage"
        case addedValue = "added_value"
        case discount
        case totalPrice = "total_price"
        case hasCoupon = "has_coupon"
        case couponMsg = "coupon_msg"
        case services
    }
}

extension OrderEnquiryResponse {
    
    func getOrderSummaryData() -> [OrderDataModel] {
        return [
            OrderDataModel(title: "services_value".localized, value: price?.toPrice),
            OrderDataModel(title: "tax_value".localized, value: addedValue?.toPrice),
            OrderDataModel(title: "discount_value".localized, value: discount?.toString().toPrice),
            OrderDataModel(title: "total_value".localized ,value: totalPrice?.toPrice)
        ]
    }
}

struct OrderDataModel{
    var title: String?
    var value: String?
    var color : UIColor = .black
}
