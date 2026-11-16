//
//  WalletChargeVM.swift
//  Profix
//
//  Created by Haneen on 25/12/2025.
//


import Foundation
import Combine

protocol WalletChargeVMProtocol {
    var chargeWalletPublisher: Published<BaseResponse<PayOrderResponse>?>.Publisher { get }

    var validationPublisher: Published<Error?>.Publisher { get }
    
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    func chargeWalletRequest(amount : Double)
    func validateAmount(amount:String?)
}

final class WalletChargeVM: BaseViewModel,WalletChargeVMProtocol {
    
    @Published var chargeWallet: BaseResponse<PayOrderResponse>?
    @Published var validation: Error?

    var chargeWalletPublisher: Published<BaseResponse<PayOrderResponse>?>.Publisher { $chargeWallet }
    
    var validationPublisher: Published<Error?>.Publisher { $validation }
    
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
        
    func chargeWalletRequest(amount : Double){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.chargeWallet(amount: amount))
                chargeWallet = result
                isLoading = false
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func validateAmount(amount:String?) {

        do {
          let validatedAmount = try ValidationService.validateWalletRecharge(amount: amount)
            chargeWalletRequest(amount : validatedAmount)

        } catch {
            validation = error

        }
    }
}
