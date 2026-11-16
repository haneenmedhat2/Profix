//
//  HomeResponse.swift
//  Profix
//
//  Created by Haneen on 31/12/2025.
//

import Foundation

struct HomeResponse: Codable {
    let ads: [Ad]?
    let categories: [HomeCategory]?
    let size: String
    let type: SectionType
    let category: SectionCategory
    let rows: Int
}

enum SectionType: String, Codable {
    case normal
    case vertical
}

enum SectionCategory: String, Codable {
    case ads
    case categories
}

struct HomeCategory: Codable {
    var id: Int
    let name: String
    let slug: String
    let image: String
    let status: CategoryStatus?
}

enum CategoryStatus: String, Codable {
    case pending
    case active
}

struct Ad: Codable {
    let id: Int?
    let image: String?
    let title : String?
    let content : String?
    let cover : String?
}

enum Section: Int, CaseIterable {
    case banner
    case categories
}
