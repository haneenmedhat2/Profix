//
//  ContactUsVMProtocol.swift
//  Profix
//
//  Created by Haneen on 29/12/2025.
//


import Foundation
import Combine

protocol ContactUsVMProtocol {
    
    var contactUsPublisher: Published<BaseResponse<String>?>.Publisher { get }
    var sitePhonePublisher: Published<String?>.Publisher { get }
    var validationPublisher: Published<Error?>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }

    func validateInputs(model: ContactUsModel)
    func getSitePhone()
}

final class ContactUsVM: BaseViewModel,ContactUsVMProtocol {
    
    @Published var contactUs: BaseResponse<String>?
    @Published var sitePhone: String?
    @Published var validationError: Error?

    var contactUsPublisher: Published<BaseResponse<String>?>.Publisher { $contactUs }
    var sitePhonePublisher: Published<String?>.Publisher { $sitePhone }
    var validationPublisher: Published<Error?>.Publisher { $validationError }

    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    func getSitePhone() {
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.sitePhone())
                sitePhone = result.data?.sitePhone
                isLoading = false
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    private func contactUsWithToken(model: ContactUsModel) {
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(
                    MoreEndpoints.contactUs(
                        token: UserDefaults.accessToken ?? "",
                        model: model
                    )
                )
                contactUs = result
                isLoading = false
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    private func contactUsWithoutToken(model: ContactUsModel) {
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(
                    MoreEndpoints.contactUs(model: model)
                )
                contactUs = result
                isLoading = false
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateInputs(model: ContactUsModel) {
        switch UserMode.current {
        case .authenticated:
            validateAuthenticatedUser(model: model)
            
        case .guest:
            validateGuestUser(model: model)
        }
    }
    
    private func validateAuthenticatedUser(model: ContactUsModel)  {
        
        do {
            _ = try ValidationService.validate(message: model.message)
            
            let requestModel = ContactUsModel(
                name: nil,
                phone: nil,
                message: model.message,
            )
            contactUsWithToken(model: requestModel)
        }catch{
            validationError = error
        }
    }
    
    private func validateGuestUser(model: ContactUsModel)  {
        
        do {
            _ = try ValidationService.validate(name: model.name)
            _ = try ValidationService.validate(phone: model.phone)
            _ = try ValidationService.validate(message: model.message)
            
            contactUsWithoutToken(model: model)
            
        }catch{
            validationError = error
        }
    }
}
