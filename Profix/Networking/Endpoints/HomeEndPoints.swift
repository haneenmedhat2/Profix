//
//  HomeEndPoints.swift
//  Esterad
//
//  Created by Haneen on 08/09/2025.
//

import Foundation
import Alamofire

struct HomeEndPoints {
    private init() {}
}

extension HomeEndPoints {
    
    static func getHomeData() -> Endpoint<BaseResponse<[HomeResponse]>>{
        return .init(
            method: .get,
            path: "home"
        )
    }

    static func getSubcategories(categoryId : Int)
    -> Endpoint<BaseResponse<SubCategoryResponse>> {

        return .init(
            method: .get,
            path: "subcategories",
            queries: [
                "category_id": categoryId
            ]
        )
    }
    
    static func getAllDelegates(model : AllDelegateModel, page : Int)
    -> Endpoint<BaseResponse<AllDelegateResponse>> {

        let latitude: Double? = model.lat == 0 ? nil : model.lat
        let longitude: Double? = model.long == 0 ? nil : model.long

        return .init(
            method: .get,
            path: "all-delegate",
            queries: [
                "subcategory_id": model.subcategoryId,
                "lat" : latitude,
                "long" : longitude,
                "city_id" : model.cityId,
                "rate" : model.rate,
                "page": page
            ],
            headerType: .ifAuthorized(token: Session.isLogin == true ? Session.token : nil)
        )
    }

    static func searchDelegates(name : String?, mainId : Int , subId : Int)
    -> Endpoint<BaseResponse<AllDelegateResponse>> {

        return .init(
            method: .get,
            path: "search",
            queries: [
                "name": name,
                "category_id" : mainId,
                "subcategory_id" : subId
            ]
        )
    }
    
    static func delegateDetails(delegateId: Int, categoryId: Int)
    -> Endpoint<BaseResponse<ProviderDetailsResponse>> {

        return .init(
            method: .get,
            path: "details-delegate",
            queries: [
                "delegate_id": delegateId,
                "category_id": categoryId
            ]
        )
    }
    
    static func delegateReviews(delegateId : Int)
    -> Endpoint<BaseResponse<ReviewResponse>> {

        return .init(
            method: .get,
            path: "delegate-reviews",
            queries: [
                "delegate_id": delegateId
            ]
        )
    }
    
    static func allServices(delegateId: Int, categoryId: Int)
    -> Endpoint<BaseResponse<ServicesResponse>> {

        return .init(
            method: .get,
            path: "all-services",
            queries: [
                "delegate_id": delegateId,
                "category_id": categoryId
            ]
        )
    }
    
    static func createProviderReview(model : CustomerReviewModel)
    -> Endpoint<BaseResponse<String>> {

        return .init(
            method: .post,
            path: "review-user",
            body: [
                "order_id" : model.orderId,
                "seconduser_id" : model.secondUserId,
                "rate" : model.rate,
                "comment" : model.comment
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func checkCouponRequest(coupon : String?)
    -> Endpoint<BaseResponse<String>> {

        return .init(
            method: .post,
            path: "check-coupon",
            body: [
                "coupon" : coupon,
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }

    
    static func orderEnquiryRequest(coupon: String?, services: [SelectedService])
    -> Endpoint<BaseResponse<OrderEnquiryResponse>> {

        let servicesPayload = try? JSONEncoder().encode(services)
        let servicesJSON = servicesPayload.flatMap { String(data: $0, encoding: .utf8) }

        return .init(
            method: .post,
            path: "order-enquiry",
            body: [
                "coupon" : coupon,
                "services" : servicesJSON
            ],
            headerType: .authorized(token: Session.token ?? "")
        )
    }
    
    static func createOrder(model : CreateOrderModel)
    -> Endpoint<BaseResponse<CreateOrderResponse>> {

        return .init(
            method: .post,
            path: "create-order",
            body: [
                "category_id" : model.categoryId,
                "subcategory_id" : model.subcategoryId,
                "delegate_id" : model.delegateId,
                "services" : model.servicesPayload,
                "date" : model.date,
                "time" : model.time,
                "lat" : model.lat,
                "long" : model.long,
                "address" : model.address,
                "description" : model.description,
                "coupon" : model.coupon
            ],
            headerType: .authorized(token: Session.token ?? ""),
            uploads: model.uploadData
        )
    }
}
