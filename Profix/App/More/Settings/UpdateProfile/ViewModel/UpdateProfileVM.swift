//
//  UpdateProfileVM.swift
//  Esterad
//
//  Created by Haneen on 03/11/2025.
//

import Foundation
import Combine

protocol UpdateProfileVMProtocol {
    
    var updateProfilePublisher: Published<BaseResponse<ProfileResponseModel>?>.Publisher { get }
    var cityPublisher: Published<BaseResponse<CityResponse>?>.Publisher { get }
    var validationPublisher: Published<Error?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var image : Data? { get set }
    var citiesList : [CityModel] { get }
    var selectedCity : SelectionModelPicker? { get set }

    func getCities()
    func updateProfileRequest(model: UpdateProfileModel)
    func validateUserData(model: UpdateProfileModel)
}

final class UpdateProfileVM: BaseViewModel,UpdateProfileVMProtocol {
    @Published var updateProfile: BaseResponse<ProfileResponseModel>?
    @Published var city: BaseResponse<CityResponse>?
    @Published var validation: Error?

    var updateProfilePublisher: Published<BaseResponse<ProfileResponseModel>?>.Publisher { $updateProfile }
    var cityPublisher: Published<BaseResponse<CityResponse>?>.Publisher { $city }
    var validationPublisher: Published<Error?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var image : Data?
    var citiesList : [CityModel] = []
    var selectedCity : SelectionModelPicker?
    
    func updateProfileRequest(model: UpdateProfileModel){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.updateProfile(model: model, uploads: model.uploadData))
                Session.user = result.data?.user
                updateProfile = result
                isLoading = false
                
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

                city = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateUserData(model: UpdateProfileModel) {
        do {
            _ = try ValidationService.validate(name: model.name)
            _ = try ValidationService.validate(cityId: selectedCity?.pickerId)
            updateProfileRequest(model:model)
            
        }catch{
            validation = error
        }
    }
}
