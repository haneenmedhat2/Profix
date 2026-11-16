//
//  OrderDetailsModel.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import Foundation
import UIKit

struct OrderDetailsResponse: Codable {
    let order: OrderDetailsModel
}

struct OrderDetailsModel: Codable {
    
    let id: Int?
    let createdAt: String?
    let status: OrderStatus?
    let statusText: String?
    let paymentType: PaymentType?
    let paymentTypeText: String?
    let paymentStatus: Bool?
    let lat: String?
    let long: String?
    let address: String?
    let time: String?
    let date: String?
    let updateTime: String?
    let updateDate: String?
    let updateStatus: String?
    let haveInvoice: Bool?
    let invoiceOrder: OrderStatus?
    let type: String?
    let price: String?
    let priceService: String?
    let appPercentage: String?
    let addedValue: String?
    let discount: String?
    let totalPrice: String?
    let invoiceImage: String?
    let description: String?
    let delegateId: Int?
    let delegateName: String?
    let delegatePhone: String?
    let delegateAvatar: String?
    let delegateLat: String?
    let delegateLong: String?
    let delegateNumOrders: String?
    let delegateRate : String?
    let userId: Int?
    let userName: String?
    let userPhone: String?
    let userAvatar: String?
    let roomId: Int?
    let services: [Service]?
    let images: [OrderImage]?
    let review: Reviews?
    let paymentInvoice: String?
    let paymentInvoiceText: String?
    let reasonRefusedInvoice: String?
    let closeReason: String?
    let isRate: Bool?
    let code: String?
    let paymentDuration: String?
    let paymentDurationUnit: String?
    let orderTimeEditLimit: String?
    let orderTimeEditLimitUnit: String?
    let image: String?
    let name: String?
    let invoiceUrl : String?
    let paymentTimeoutMessage : String?
    let paymentTimeoutTimer: Int?
    let acceptTimeoutClock: String?
    let acceptTimeoutHours: Int?
    let acceptTimeoutMessage: String?
    let acceptTimeoutMinutes: Int?
    let acceptTimeoutSeconds: Int?
    let acceptTimeoutTimer: Int?
    let pledge: String?
    let pledgeSeen: Bool?
    
    enum CodingKeys: String, CodingKey {
           case id
           case createdAt = "created_at"
           case status
           case statusText = "status_text"
           case paymentType = "payment_type"
           case paymentTypeText = "payment_type_text"
           case paymentStatus = "payment_status"
           case lat, long, address,time, date
           case updateTime = "update_time"
           case updateDate = "update_date"
           case updateStatus = "update_status"
           case haveInvoice = "have_invoice"
           case invoiceOrder = "invoice_order"
           case type, price
           case priceService = "price_service"
           case appPercentage = "app_percentage"
           case addedValue = "added_value"
           case discount
           case totalPrice = "total_price"
           case invoiceImage = "invoice_image"
           case description
           case delegateId = "delegate_id"
           case delegateName = "delegate_name"
           case delegatePhone = "delegate_phone"
           case delegateAvatar = "delegate_avatar"
           case delegateLat = "delegate_lat"
           case delegateLong = "delegate_long"
           case delegateNumOrders = "delegate_num_orders"
           case delegateRate = "delegate_rate"
           case userId = "user_id"
           case userName = "user_name"
           case userPhone = "user_phone"
           case userAvatar = "user_avatar"
           case roomId = "room_id"
           case services, images,review
           case paymentInvoice = "payment_invoice"
           case paymentInvoiceText = "payment_invoice_text"
           case reasonRefusedInvoice = "reason_refused_invoice"
           case closeReason = "close_reason"
           case isRate = "is_rate"
           case code
           case paymentDuration = "payment_duration"
           case paymentDurationUnit = "payment_duration_unit"
           case orderTimeEditLimit = "order_time_edit_limit"
           case orderTimeEditLimitUnit = "order_time_edit_limit_unit"
           case image, name
           case invoiceUrl = "invoice_url"
           case paymentTimeoutMessage = "payment_timeout_message"
           case paymentTimeoutTimer = "payment_timeout_timer"
           case acceptTimeoutClock = "accept_timeout_clock"
           case acceptTimeoutHours = "accept_timeout_hours"
           case acceptTimeoutMessage = "accept_timeout_message"
           case acceptTimeoutMinutes = "accept_timeout_minutes"
           case acceptTimeoutSeconds = "accept_timeout_seconds"
           case acceptTimeoutTimer = "accept_timeout_timer"
           case pledge
           case pledgeSeen = "pledge_seen"
       }
}

extension OrderDetailsModel {
    func getOrderDetailsList() -> [OrderDataModel] {
        
        let color = status == .closed ? UIColor.red : UIColor.black
        var orderDetailsList : [OrderDataModel] = []
        orderDetailsList.append(OrderDataModel(title: "order_status".localized , value: statusText,color: color))
        orderDetailsList.append(OrderDataModel(title: "order_date".localized, value: date))
        orderDetailsList.append(OrderDataModel(title: "order_time".localized, value: time))
        
        if status == .inprogress || status == .finished {
            orderDetailsList.append(OrderDataModel(title: "warranty_code".localized , value: code))
        }
        
        return orderDetailsList
    }

    func getRequestedServicesList() -> [OrderDataModel] {
        return (services ?? []).compactMap { service -> OrderDataModel? in
            guard let name = service.name else { return nil }
            return OrderDataModel(
                title: name,
                value: service.executionCountText
            )
        }
    }
    
    func getOrderSummaryData() -> [OrderDataModel] {
        return [
            OrderDataModel(title: "services_value".localized, value: price?.toPrice),
            OrderDataModel(title: "tax_value".localized, value: addedValue?.toPrice),
            OrderDataModel(title: "discount_value".localized, value: discount?.toPrice),
            OrderDataModel(title: "total_value".localized ,value: totalPrice?.toPrice)
        ]
    }
    
    func getProblemDescImages() -> [ProblemDescImageType] {
       return images?.map {
            .remote($0.url)
        } ?? []
    }
}

extension OrderDetailsModel {
    var isCancelButtonHidden : Bool {
        return !(status == .open)
    }
    
    var isPayButtonHidden : Bool {
        return !(status == .accepted && paymentStatus == false )
    }
    
    var isCancelViewHidden : Bool {
        let closeReason = self.closeReason ?? ""
        return !(status == .closed && !closeReason.trimWhiteSpace().isEmpty )
    }
    
    var isFeedbackViewHidden : Bool {
        return !(status == .finished && isRate == true )
    }
    
    var isEditTimeCancelOrderStackHidden : Bool {
        return !(status == .scheduled)
    }
    
    var isOrderNotesHidden : Bool {
        return !(status == .scheduled || (status == .inprogress && haveInvoice == true && invoiceOrder != .accepted && invoiceOrder != .refused))
    }
    
    var isChatButtonHidden : Bool {
        return !(status == .scheduled || status == .inprogress || status == .finished)
    }
    
    var isComplaintButtonHidden : Bool {
        return !( status == .inprogress || status == .finished)
    }
    
    var isBillButtonHidden : Bool {
        return !(status == .finished && invoiceOrder == .accepted )
    }
    
    var isRateButtonHidden : Bool {
        return  !(status == .finished && isRate == false )
    }
    
    var isBillStackHidden: Bool {
        return !(status == .inprogress && haveInvoice == true && invoiceOrder != .accepted && invoiceOrder != .refused)
    }
}

struct CancelReasonsResponse : Codable {
    let reasons : [CancelReasonsModel]?
}

struct CancelReasonsModel : Codable {
    var id : Int?
    var reason : String?
    var userType : String?
    var isSelected : Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, reason
        case userType = "user_type"
    }
}

struct Service : Codable{
    let id : Int?
    let name : String?
    let price : Double?
    let quantity: Int?
    let serviceId: Int?
    let totalPrice: String?

    enum CodingKeys: String, CodingKey {
        case id, name, price, quantity
        case serviceId = "service_id"
        case totalPrice = "total_price"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        serviceId = try container.decodeIfPresent(Int.self, forKey: .serviceId)
        totalPrice = try container.decodeIfPresent(String.self, forKey: .totalPrice)

        if let numericPrice = try? container.decode(Double.self, forKey: .price) {
            price = numericPrice
        } else if let stringPrice = try? container.decode(String.self, forKey: .price) {
            price = Double(stringPrice)
        } else {
            price = nil
        }
    }
}

extension Service {
    var executionCountText: String {
        return String(
            format: "execution_count_accessibility".localized,
            quantity ?? 1
        )
    }
}

enum PaymentType: String, Codable {
    case wallet
    case cash
    case online
    case none = ""
}

enum PaymentInvoiceType: String, Codable {
    case online
    case cash
}

struct OrderImage: Codable {
    let id: Int
    let url: String
}
