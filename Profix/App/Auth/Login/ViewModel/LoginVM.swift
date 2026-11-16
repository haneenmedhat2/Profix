//
//  LoginVM.swift
//  Esterad
//
//  Created by Haneen on 15/10/2025.
//

import Foundation
import Combine

protocol LoginVMProtocol {
    
    var loginPublisher: Published<BaseResponse<LoginResponse>?>.Publisher { get }
    var validationPublisher: Published<Error?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    func loginRequest(model: LoginModel)
    func validateInputs(model: LoginModel)
}

final class LoginVM: BaseViewModel,LoginVMProtocol {
    
    @Published var login: BaseResponse<LoginResponse>?
    @Published var validationError: Error?
    
    var loginPublisher: Published<BaseResponse<LoginResponse>?>.Publisher { $login }
    var validationPublisher: Published<Error?>.Publisher { $validationError }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    func loginRequest(model: LoginModel){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(AuthEndpoints.login(model: model))
                Session.user = result.data?.user
                Session.token = result.data?.token
                isLoading = false
                login = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateInputs(model: LoginModel) {
        
        do {
            _ = try ValidationService.validate(phone: model.phone)
            _ = try ValidationService.validate(password: model.password)
            loginRequest(model: model)
            
        }catch{
            validationError = error
        }
    }
}
