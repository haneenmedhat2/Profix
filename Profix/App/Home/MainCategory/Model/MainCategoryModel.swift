//
//  MainCategoryResponse.swift
//  Profix
//
//  Created by Haneen on 01/01/2026.
//

import Foundation

struct SubCategoryResponse : Codable {
    let subcategories : [SubCategoryModel]?
}

struct SubCategoryModel : Codable {
    let id : Int?
    let name : String?
    let image : String?
    let status : String?
}


struct AllDelegateModel : Codable {
    
    var subcategoryId : Int
    var lat : Double?
    var long : Double?
    var cityId : Int?
    var rate : String?
    
    enum CodingKeys: String, CodingKey {
        case subcategoryId = "subcategory_id"
        case lat, long
        case cityId = "city_id"
        case rate
    }
}

struct AllDelegateResponse : Codable {
    let delegates : [DelegateModel]?
    let pagination : PaginationModel?
}

struct DelegateModel : Codable {
    let id : Int?
    let name : String?
    let avatar : String?
    let rate : String?
    let email : String?
    let countryKey : String?
    let phone : String?
    let changedPhone : String?
    let lat : String?
    let long : String?
    let address : String?
    let approve : String?
    let wallet : String?
    let accType : String?
    let description : String?
    let lang : String?
    let isNotify : Bool?
    let numOrders : String?
    let services : [Services]?
    let reviews : [Reviews]?
    let works : [Works]?
    let dayPeriods: ProviderDayPeriods?
    let commercialFile: String?
    
    enum CodingKeys: String, CodingKey {
        case id,name,avatar,rate,email
        case countryKey = "country_key"
        case phone
        case changedPhone = "changed_phone"
        case lat, long
        case address
        case approve
        case wallet
        case accType = "acc_type"
        case description
        case lang
        case isNotify = "is_notify"
        case services , reviews , works
        case numOrders = "num_orders"
        case dayPeriods = "day_periods"
        case commercialFile = "commercial_file"
    }
}

struct PaginationModel : Codable {
    let total : Int?
    let count : Int?
    let perPage : Int?
    let nextPageUrl : String?
    let prevPageUrl : String?
    let currentPage : Int
    let totalPages : Int
    var isLastPage: Bool {
        currentPage >= totalPages
    }
    
    enum CodingKeys: String, CodingKey {
        case total, count, perPage = "per_page", nextPageUrl = "next_page_url", prevPageUrl = "prev_page_url", currentPage = "current_page", totalPages = "total_pages"
    }
}

struct Services : Codable {
    let categoryId : Int?
    let categoryName : String?
    let description : String?
    let id : Int?
    let name : String?
    let price : String?
    let subcategoryId : Int?
    let subcategoryName : String?
    let serviceId: Int?
    let totalPrice: String?
    let canEditDelete: Bool?
    var isSelected : Bool = false
    var quantity: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id", categoryName = "category_name", description, id, name, price, subcategoryId = "subcategory_id", subcategoryName = "subcategory_name", quantity
        case serviceId = "service_id"
        case totalPrice = "total_price"
        case canEditDelete = "can_edit_delete"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        subcategoryId = try container.decodeIfPresent(Int.self, forKey: .subcategoryId)
        subcategoryName = try container.decodeIfPresent(String.self, forKey: .subcategoryName)
        serviceId = try container.decodeIfPresent(Int.self, forKey: .serviceId)
        totalPrice = try container.decodeIfPresent(String.self, forKey: .totalPrice)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        canEditDelete = try container.decodeIfPresent(Bool.self, forKey: .canEditDelete)
    }
}

struct Reviews : Codable {
    let comment : String?
    let createdAt : String?
    let id : Int?
    let rate : String?
    let userAvatar : String?
    let userName : String?
    
    enum CodingKeys: String, CodingKey {
        case comment, createdAt = "created_at", id, rate, userAvatar = "user_avatar", userName = "user_name"
    }
}

struct Works : Codable {
    let id : Int?
    let image : String?
    let categoryId: Int?
    let categoryName: String?

    enum CodingKeys: String, CodingKey {
        case id, image
        case categoryId = "category_id"
        case categoryName = "category_name"
    }
}
