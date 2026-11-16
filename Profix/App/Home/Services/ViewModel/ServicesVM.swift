//
//  ServicesVM.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import Combine

protocol ServicesVMProtocol {
    
    var services: [Services] { get set }
    var servicesPublisher: Published<[Services]>.Publisher { get }
    
    var hasSelectedServicePublisher: AnyPublisher<Bool, Never> { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var delegateId : Int { get }
    var categoryId: Int { get }
    func allServicesRequest()
    func buildOrderContext() -> OrderContext
    func toggleService(at index: Int)
    func incrementQuantity(at index: Int)
    func decrementQuantity(at index: Int)
}

final class ServicesVM : BaseViewModel , ServicesVMProtocol {
        
    @Published var services: [Services] = []

    var servicesPublisher: Published<[Services]>.Publisher { $services }
    var hasSelectedServicePublisher: AnyPublisher<Bool, Never> {
        $services
            .map { services in
                services.contains(where: { $0.isSelected })
            }
            .eraseToAnyPublisher()
    }
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    var delegateId : Int
    var categoryId: Int

    private let dayPeriods: ProviderDayPeriods?

    init(delegateId: Int, categoryId: Int, dayPeriods: ProviderDayPeriods? = nil) {
        self.dayPeriods = dayPeriods
        self.delegateId = delegateId
        self.categoryId = categoryId
    }
        
    func allServicesRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(
                    HomeEndPoints.allServices(
                        delegateId: delegateId,
                        categoryId: categoryId
                    )
                )
                isLoading = false
                guard let services  = result.data?.services else { return }
                self.services = services 
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}

extension ServicesVM {

    func toggleService(at index: Int) {
        guard services.indices.contains(index) else { return }
        services[index].isSelected.toggle()
        if services[index].isSelected {
            services[index].quantity = max(services[index].quantity, 1)
        }
    }

    func incrementQuantity(at index: Int) {
        guard services.indices.contains(index) else { return }
        services[index].quantity += 1
    }

    func decrementQuantity(at index: Int) {
        guard services.indices.contains(index) else { return }
        services[index].quantity = max(1, services[index].quantity - 1)
    }

    func buildOrderContext() -> OrderContext {

        let selected = services.filter { $0.isSelected }

            let categoryId = selected.first?.categoryId
            let subcategoryId = selected.first?.subcategoryId

        return OrderContext(
            categoryId: categoryId ?? 0,
            subCategoryId: subcategoryId ?? 0,
            delegateId: delegateId,
            services: selected.compactMap { service in
                guard let id = service.id else { return nil }
                return SelectedService(serviceId: id, quantity: service.quantity)
            },
            dayPeriods: dayPeriods
        )
    }
}
