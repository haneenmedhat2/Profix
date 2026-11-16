//
//  CreateOrderModel.swift
//  Profix
//
//  Created by Haneen on 15/01/2026.
//


import Foundation

struct CreateOrderModel  {
    
    var categoryId : Int?
    var subcategoryId : Int?
    var delegateId : Int?
    var services : [SelectedService]?

    var servicesPayload: String? {
        guard let services,
              let data = try? JSONEncoder().encode(services) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    var date : String?
    var time : String?
    var lat : Double?
    var long : Double?
    var address : String?
    var coupon : String?
    var description : String?
    var images: [Data] = []
    
    var uploadData: [UploadData] {
        var files = [UploadData]()
        
        for (index, imageData) in images.enumerated() {
            files.append(
                UploadData(
                    key: "images[\(index)]",
                    data: imageData,
                    mimeType: .jpeg,
                    fileName: "image_\(index)_\(Date().timeIntervalSince1970).jpeg"
                )
            )
        }
        
        return files
    }
     
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case subcategoryId = "subcategory_id"
        case delegateId = "delegate_id"
        case services
        case date ,time ,lat ,long , description
    }
}


struct CreateOrderResponse : Codable {
    let orderId : Int
    
    enum CodingKeys : String , CodingKey {
        case orderId = "order_id"
    }
}


enum ProblemDescImageType {
    case local(Data)
    case remote(String)
}
