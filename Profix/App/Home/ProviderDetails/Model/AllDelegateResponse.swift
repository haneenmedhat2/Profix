//
//  AllDelegateResponse.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//


struct ProviderDetailsResponse : Codable {
    let delegate : DelegateModel?
}

enum HeaderTypes {
    case services
    case previousWorks
    case customerReviews
    
    var isShowAllHidden : Bool {
        switch self {
        case .services,.customerReviews:
            return false
        case .previousWorks:
            return true 
        }
    }
}

enum ServiceCellMode {
    case full
    case simple 
}
