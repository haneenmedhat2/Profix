//
//  Services.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//


struct ServicesResponse : Codable {
    let services : [Services]
}

struct OrderContext : Codable {
    let categoryId : Int
    let subCategoryId : Int
    let delegateId : Int
    let services : [SelectedService]
    var dayPeriods: ProviderDayPeriods? = nil
}

struct SelectedService: Codable {
    let serviceId: Int
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case serviceId = "service_id"
        case quantity
    }
}
