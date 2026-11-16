//
//  EditServiceTimeVM.swift
//  Profix
//
//  Created by Haneen on 19/01/2026.
//


import Foundation
import Combine

protocol EditServiceTimeVMProtocol {
    
    var editTimePublisher: Published<BaseResponse<String>?>.Publisher { get }
    var validationPublisher: Published<ValidationError?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var orderId : Int { get }
    
    func editTimeRequest(date : String , time : String )
    func validateUserData(date : String? ,time : String? ) -> Bool
}

final class EditServiceTimeVM : BaseViewModel , EditServiceTimeVMProtocol {
    
    @Published var editTime: BaseResponse<String>?
    @Published var validation: ValidationError?
    
    var editTimePublisher: Published<BaseResponse<String>?>.Publisher { $editTime }
    var validationPublisher: Published<ValidationError?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var orderId : Int
    init(orderId : Int){
        self.orderId = orderId
    }

    
    func editTimeRequest(date : String , time : String ){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(OrderDetailsEndPoints.updateDate(orderId: orderId, date: date, time: time))
                isLoading = false
                editTime = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateUserData(date : String? ,time : String? ) -> Bool {
        var validatedDate : String
        var validatedTime : String
        
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
        
        editTimeRequest(date : validatedDate , time : validatedTime )
        return true
    }
}
