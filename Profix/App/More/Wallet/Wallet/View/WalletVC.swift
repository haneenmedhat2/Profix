//
//  WalletVC.swift
//  Profix
//
//  Created by Haneen on 25/12/2025.
//

import UIKit
import Combine

class WalletVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    //MARK: - Properties -
    
    let viewModel : WalletVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : WalletVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "WalletVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad(){
        super.viewDidLoad()
        initialConfiguration()
    }
    
    //MARK: - Initial Setup -
    
    func initialConfiguration() {
        self.title = "wallet".localized
        bindViewModel()
        viewModel.showWalletRequest()
    }
    
    //MARK: - ViewModel Binding -
    
    private func bindViewModel() {
        
        loading(viewModel.isLoadingPublisher)
        
        viewModel.showWalletPublisher
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.balanceLabel.text = result?.data?.wallet.toPrice
            }
            .store(in: &cancellables)
                
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Actions -
    
    @IBAction func didTapWalletRecharge(_ sender: UIButton) {
        goToWalletRecharge()
    }
}
//MARK: - Routes -

extension WalletVC {
    
    func goToWalletRecharge() {
        let vc = WalletChargeVC(viewModel: WalletChargeVM())
        vc.delegate = self
        push(vc)
    }
}

//MARK: - WalletPopup Delegation -

extension WalletVC : WalletChargeProtocol {
    func didChargeWallet() {
        viewModel.showWalletRequest()
    }
}
