//
//  HomeVM.swift
//  Profix
//
//  Created by Haneen on 31/12/2025.
//


import Foundation
import Combine

protocol HomeVMProtocol {
    var homePublisher: Published<[HomeResponse]>.Publisher { get }
    var sitePhonePublisher: Published<String?>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }

    var ads : [Ad] { get }
    var categoriesList : [HomeCategory] { get }
    func homeRequest()
    func getSitePhone()
    func changeLanguageRequest()

}

final class HomeVM : BaseViewModel , HomeVMProtocol {
    @Published var home: [HomeResponse] = []
    @Published var sitePhone: String?

    var homePublisher: Published<[HomeResponse]>.Publisher { $home }
    var sitePhonePublisher: Published<String?>.Publisher { $sitePhone }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }

    var ads : [Ad] = []
    var categoriesList : [HomeCategory] = []

    func getSitePhone() {
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.sitePhone())
                sitePhone = result.data?.sitePhone
            } catch {
                print("Failed to load site phone: \(error.localizedDescription)")
            }
        }
    }

    func homeRequest() {
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(HomeEndPoints.getHomeData())
                isLoading = false
                
                if let adsSection = result.data?.first(where: { $0.category == .ads }) {
                    ads = adsSection.ads ?? []
                }
                
                if let categoriesSection = result.data?.first(where: { $0.category == .categories }) {
                    categoriesList = categoriesSection.categories ?? []
                }
                
                home = result.data ?? []
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func changeLanguageRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.changeLanguage())
                isLoading = false
                Session.user = result.data
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
