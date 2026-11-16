//
//  MainCategoryVM.swift
//  Profix
//
//  Created by Haneen on 01/01/2026.
//

import Foundation
import UIKit
import Combine
import CoreLocation

protocol MainCategoryVMProtocol {
    
    var subcategories: [SubCategoryModel] { get }
    var delegates: [DelegateModel] { get }
    
    var subcategoriesPublisher: Published<[SubCategoryModel]>.Publisher { get }
    var delegatesPublisher: Published<[DelegateModel]>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var categoryModel : HomeCategory { get }
    var model: AllDelegateModel { get set }
    var selectedIndex : IndexPath { get set }
    var filterState : FilterState { get }
    var currentPage : Int { get }
    var isLastPage: Bool { get }

    func subcategoryRequest()
    func allDelegatesRequest()
    func applyFilter(state : FilterState)
    func resetData()

}

final class MainCategoryVM : BaseViewModel , MainCategoryVMProtocol {
    
    @Published private(set) var subcategories: [SubCategoryModel] = []
    @Published private(set) var delegates: [DelegateModel] = []

    var subcategoriesPublisher: Published<[SubCategoryModel]>.Publisher { $subcategories }
    var delegatesPublisher: Published<[DelegateModel]>.Publisher { $delegates }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var model: AllDelegateModel
    
    var selectedIndex : IndexPath = IndexPath(row: 0, section: 0)
    var filterState = FilterState()
    var currentPage:Int = 1
    var isLastPage: Bool = false

    var categoryModel : HomeCategory
    init(categoryModel : HomeCategory){
        self.categoryModel = categoryModel
        let authorizationStatus = CLLocationManager.authorizationStatus()
        let hasLocationAccess = authorizationStatus == .authorizedAlways ||
            authorizationStatus == .authorizedWhenInUse
        let location = hasLocationAccess ? UserDefaults.currentLocation : nil
        self.model = AllDelegateModel(
            subcategoryId: 0,
            lat: location?.lat,
            long: location?.long,
            cityId: nil,
            rate: nil
        )
    }

    func subcategoryRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.getSubcategories(categoryId: categoryModel.id))
                isLoading = false
                self.subcategories = result.data?.subcategories ?? []

                if let first = self.subcategories.indices.first {
                    model.subcategoryId = self.subcategories[first].id ?? 0
                    allDelegatesRequest()
                }

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func allDelegatesRequest(){
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.getAllDelegates(model: model, page: currentPage))
                
                let delegates = result.data?.delegates ?? []
                
                if currentPage == 1 {
                    self.delegates.removeAll()
                    self.delegates = delegates
                } else {
                    self.delegates.append(contentsOf: delegates)
                }
                
                isLastPage = result.data?.pagination?.isLastPage ?? false
                if !isLastPage {
                    currentPage += 1
                }
                isLoading = false

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func applyFilter(state : FilterState) {
        self.filterState = state
        model.cityId = state.selectedCity?.pickerId
        model.rate = state.selectedRate?.apiValue
        resetData()
        allDelegatesRequest()
    }
    
    func resetData(){
        currentPage = 1
        isLastPage = false
    }
}
