//
//  CustomerReviewVM.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import Foundation
import Combine

protocol CustomerReviewVMProtocol {
    
    var customerReviewsList : [Reviews] { get }
    var delegateReviewsPublisher: Published<[Reviews]>.Publisher { get }
    var reviewPublisher: Published<BaseResponse<String>?>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var delegateId : Int { get }
    func delegateReviewsRequest()
    func createReview(model : CustomerReviewModel)
}

final class CustomerReviewVM : BaseViewModel , CustomerReviewVMProtocol {
    
    @Published var review : BaseResponse<String>?
    @Published var customerReviewsList : [Reviews] = []

    var delegateReviewsPublisher: Published<[Reviews]>.Publisher { $customerReviewsList }
    var reviewPublisher: Published<BaseResponse<String>?>.Publisher { $review }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var delegateId : Int
    init(delegateId : Int ){
        self.delegateId = delegateId
    }
        
    func delegateReviewsRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.delegateReviews(delegateId: delegateId))
                isLoading = false
                customerReviewsList = result.data?.reviews ?? []
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func createReview(model : CustomerReviewModel){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.createProviderReview(model: model))
                delegateReviewsRequest()
                isLoading = false
                review = result
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
