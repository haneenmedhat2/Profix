//
//  RateTypes.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import Foundation

enum RateTypes : CaseIterable {
    case highest
    case lowest
    
    var id : Int {
        switch self {
        case .highest:
            return 1
        case .lowest:
            return 2
        }
    }
    
    var title : String {
        switch self {
        case .highest:
            return "highest_rating".localized
        case .lowest:
            return "lowest_rating".localized
        }
    }
    
    var apiValue : String {
        switch self {
        case .highest:
            return "highest"
        case .lowest:
            return "lowest"
        }
    }
}


struct FilterState {
    var selectedRate : RateTypes?
    var selectedCity : SelectionModelPicker?
}
