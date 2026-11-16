//
//  WalletVM.swift
//  Profix
//
//  Created by Haneen on 25/12/2025.
//

import Foundation
import Combine

protocol WalletVMProtocol {
    var showWalletPublisher: Published<BaseResponse<WalletResponse>?>.Publisher { get }

    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    func showWalletRequest()
}

final class WalletVM: BaseViewModel,WalletVMProtocol {
    
    @Published var showWallet: BaseResponse<WalletResponse>?

    var showWalletPublisher: Published<BaseResponse<WalletResponse>?>.Publisher { $showWallet }

    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }
    
    func showWalletRequest(){
        isLoading = true
        Task {
            do {
                let result = try await getAllRequest(MoreEndpoints.showWallet())
                showWallet = result
                isLoading = false
                
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}
