//
//  IntroModel.swift
//  Profix
//
//  Created by Haneen on 08/12/2025.
//


struct IntroResponse : Codable {
    var intros : [IntroModel]?
}

struct IntroModel : Codable {
    let id : Int?
    let title: String?
    let desc: String?
    let image: String?
}
