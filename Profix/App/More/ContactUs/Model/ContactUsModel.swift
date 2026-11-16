//
//  ContactUsModel.swift
//  Profix
//
//  Created by Haneen on 29/12/2025.
//


import Foundation

struct ContactUsModel : Codable {
    let name : String?
    let phone : String?
    let message : String?
}

struct SitePhoneResponse : Codable {
    let sitePhone : String?

    enum CodingKeys : String, CodingKey {
        case sitePhone = "site_phone"
    }
}

