//
//  SearchProvidersVM.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//


import Foundation
import UIKit
import Combine

protocol SearchProvidersVMProtocol {
    
    var delegates: [DelegateModel]  { get }
    var delegatesPublisher: Published<[DelegateModel]>.Publisher { get }
    var searchSubject : PassthroughSubject<String, Never> { get set }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var mainCategoryId : Int { get }
    var subCategoryId : Int { get }
    var searchQuery : String? { get set }

    func searchDelegates()
}

final class SearchProvidersVM : BaseViewModel , SearchProvidersVMProtocol {
    
    @Published private(set) var delegates: [DelegateModel] = []
    var delegatesPublisher: Published<[DelegateModel]>.Publisher { $delegates }
    var searchSubject = PassthroughSubject<String, Never>()

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var mainCategoryId : Int
    var subCategoryId : Int
    var searchQuery : String?

    init(mainCategoryId : Int , subCategoryId : Int){
        self.mainCategoryId = mainCategoryId
        self.subCategoryId = subCategoryId
    }
        
    func searchDelegates(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.searchDelegates(name: searchQuery, mainId: mainCategoryId, subId: subCategoryId))
                isLoading = false
                delegates = result.data?.delegates ?? []
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
    
