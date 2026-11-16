//
//  BookingLocationVM.swift
//  Profix
//
//  Created by Haneen on 12/01/2026.
//

import Foundation
import Combine

protocol BookingLocationVMProtocol {
    
    var onLocationSelected: ((AddressModel) -> Void)? { get set}
    var selectedAddress: AddressModel? {get set }
}

final class BookingLocationVM : BaseViewModel , BookingLocationVMProtocol {
    
    var onLocationSelected: ((AddressModel) -> Void)?
    var selectedAddress: AddressModel?
}
