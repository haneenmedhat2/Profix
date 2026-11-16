//
//  FilterPopupVM.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import Foundation
import Combine

protocol FilterPopupVMProtocol {
    var cities : [CityModel] { get }
    var cityPublisher: Published<[CityModel]>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var selectedCity : SelectionModelPicker? { get set }
    var selectedRate : RateTypes? { get set }
    var rateList : [RateTypes] { get }
    
    func getCities()
}

final class FilterPopupVM: BaseViewModel,FilterPopupVMProtocol {
    
    @Published private(set) var cities: [CityModel] = []
    var cityPublisher: Published<[CityModel]>.Publisher { $cities }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var selectedCity : SelectionModelPicker?
    var selectedRate : RateTypes?

    var rateList : [RateTypes] = RateTypes.allCases
    
    init(state : FilterState){
        self.selectedCity = state.selectedCity
        self.selectedRate = state.selectedRate
    }
    
    func getCities(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(AuthEndpoints.getCities(countryId: 1))
                isLoading = false
                cities = result.data?.cities ?? []
                cities = cities.reversed()

            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
