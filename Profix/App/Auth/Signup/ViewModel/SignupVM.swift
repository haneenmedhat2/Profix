//
//  SignupVM.swift
//  Esterad
//
//  Created by Haneen on 18/10/2025.
//

import Foundation
import Combine

protocol SignupVMProtocol {
    var signupPublisher: Published<BaseResponse<LoginResponse>?>.Publisher { get }
    var cityPublisher: Published<[CityModel]>.Publisher { get }

    var validationPublisher: Published<Error?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var isChecked : Bool { get set }
    var image : Data? { get set }
    var citiesList : [CityModel] { get }
    var selectedCity : SelectionModelPicker? { get set }
    
    func register(model: SignupModel)
    func getCities()
    func validateUserData(model: SignupModel)
}

final class SignupVM: BaseViewModel,SignupVMProtocol {
    
    @Published var signup: BaseResponse<LoginResponse>?
    @Published var citiesList: [CityModel] = []

    @Published var validation: Error?
    
    var signupPublisher: Published<BaseResponse<LoginResponse>?>.Publisher { $signup }
    var cityPublisher: Published<[CityModel]>.Publisher { $citiesList}

    var validationPublisher: Published<Error?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var isChecked : Bool = false
    var image : Data?
    var selectedCity : SelectionModelPicker?

    func register(model: SignupModel) {
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(AuthEndpoints.signup(model: model, uploads: model.uploadData))
                isLoading = false
                signup = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func getCities(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(AuthEndpoints.getCities(countryId: 1))
                isLoading = false
                citiesList = result.data?.cities ?? []
                citiesList = citiesList.reversed()

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateUserData(model: SignupModel)  {
      
        do {
            _ = try ValidationService.validate(name: model.name)
            _ = try ValidationService.validate(cityId: selectedCity?.pickerId)
            _ = try ValidationService.validate(phone: model.phone)
            _ = try ValidationService.validate(password: model.password)
            _ = try ValidationService.validate(newPassword: model.password, confirmPassword: model.confirmPassword)
            _ = try ValidationService.validate(termesAgreed: isChecked )
            register(model: model)
            
        }catch{
            validation = error
        }
    }
}

