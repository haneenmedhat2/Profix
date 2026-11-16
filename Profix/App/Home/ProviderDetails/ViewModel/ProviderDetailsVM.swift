//
//  ProviderDetailsVM.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import Combine

protocol ProviderDetailsVMProtocol {
    
    var providerDetails: DelegateModel? { get }
    var servicesList : [Services] { get }
    var previousWorkList : [Works] { get }
    var customerReviewsList : [Reviews] { get }
    var providerDetailsPublisher: Published<DelegateModel?>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var delegateId : Int { get }
    func delegateDetailsRequest()
}

final class ProviderDetailsVM : BaseViewModel , ProviderDetailsVMProtocol {
    
    @Published var providerDetails: DelegateModel?
    var servicesList : [Services] = []
    var previousWorkList : [Works] = []
    var customerReviewsList : [Reviews] = []

    var providerDetailsPublisher: Published<DelegateModel?>.Publisher { $providerDetails }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var delegateId : Int
    private let categoryId: Int

    init(delegateId: Int, categoryId: Int) {
        self.delegateId = delegateId
        self.categoryId = categoryId
    }
        
    func delegateDetailsRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.delegateDetails(delegateId: delegateId, categoryId: categoryId))
                isLoading = false
                guard let delegateDetails  = result.data?.delegate else { return }
                servicesList = delegateDetails.services ?? []
                previousWorkList = delegateDetails.works ?? []
                customerReviewsList = delegateDetails.reviews ?? []
                providerDetails = delegateDetails
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
