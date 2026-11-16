//
//  ReviewResponse.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import Foundation


struct ReviewResponse : Codable {
    let reviews : [Reviews]?
}

struct CustomerReviewModel : Codable {
    let orderId : Int?
    let secondUserId : Int
    let rate : Double
    let comment : String?
}

