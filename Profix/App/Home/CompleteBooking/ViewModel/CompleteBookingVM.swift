//
//  CompleteBookingVM.swift
//  Profix
//
//  Created by Haneen on 12/01/2026.
//

import Foundation
import Combine

protocol CompleteBookingVMProtocol {
    
    var orderEnquiryPublisher: Published<BaseResponse<OrderEnquiryResponse>?>.Publisher { get }
    var validationPublisher: Published<ValidationError?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var orderModel : CreateOrderModel { get set }
    
    func availablePeriods(for date: String) -> [ProviderDayPeriod]
    func orderEnquiryRequest()
    func validateUserData(date : String? ,time : String? , address : String? , desc : String? ) -> Bool
}

final class CompleteBookingVM : BaseViewModel , CompleteBookingVMProtocol {
    
    @Published var orderEnquiry: BaseResponse<OrderEnquiryResponse>?
    @Published var validation: ValidationError?
    
    var orderEnquiryPublisher: Published<BaseResponse<OrderEnquiryResponse>?>.Publisher { $orderEnquiry}
    var validationPublisher: Published<ValidationError?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var orderModel : CreateOrderModel = CreateOrderModel()
    
    private let dayPeriods: ProviderDayPeriods?

    init(model: OrderContext) {
        dayPeriods = model.dayPeriods
        orderModel.categoryId = model.categoryId
        orderModel.subcategoryId = model.subCategoryId
        orderModel.delegateId = model.delegateId
        orderModel.services = model.services
    }
    
    func availablePeriods(for date: String) -> [ProviderDayPeriod] {
        dayPeriods?.availablePeriods(on: date) ?? ProviderDayPeriods.unrestrictedPeriods(on: date)
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
                orderEnquiry = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateUserData(date : String? ,time : String? , address : String? , desc : String? ) -> Bool  {
        var validatedDate : String
        var validatedTime : String
        var validatedAddress : String
        var validatedDesc : String
        
        switch ValidationService.validate(executionDate: date) {
        case .success(let validDate):
            validatedDate = validDate
            
        case .failure(let error):
            validation = error
            return false
        }
        
        
        switch ValidationService.validate(executionTime: time) {
        case .success(let validTime ):
            validatedTime = validTime
            
        case .failure(let error):
            validation = error
            return false
        }
        
        let periods = availablePeriods(for: validatedDate)
        if !periods.contains(where: { $0.allows(time: validatedTime, on: validatedDate) }) {
            validation = .unavailableBookingTime
            return false
        }

        switch ValidationService.validate(executionLocation: address){
        case .success(let validAddress):
            validatedAddress = validAddress
            
        case .failure(let error):
            validation = error
            return false
        }
        
        
        switch ValidationService.validate(desc: desc){
        case .success(let validateDesc):
            validatedDesc = validateDesc
            
        case .failure(let error):
            validation = error
            return false
        }
         
        orderModel.date = validatedDate
        orderModel.time = validatedTime
        orderModel.address = validatedAddress
        orderModel.description = validatedDesc
        
        orderEnquiryRequest()
        return true
    }
}
