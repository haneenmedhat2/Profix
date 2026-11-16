//
//  WalletChargeVC.swift
//  Profix
//
//  Created by Haneen on 25/12/2025.
//

import UIKit
import Combine

class WalletChargeVC: BaseViewController {

    //MARK: - Outlets -
    
    @IBOutlet weak var walletChargeTextField: GeneralTextField!
    
    //MARK: - Properite -
    
    var viewModel : WalletChargeVMProtocol
    var delegate : WalletChargeProtocol?
    
    //MARK: - Initializer -
    
    init(viewModel : WalletChargeVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "WalletChargeVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - LifeCycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfigurations()
    }
    
    //MARK: - Configurations -
    
    func initialConfigurations(){
        self.title =  "top_up_balance".localized
        bindViewModel()
    }
    
    //MARK: - ViewModel Binding -
    
    private func bindViewModel() {
        
        loading(viewModel.isLoadingPublisher)
        
        viewModel.chargeWalletPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                if let paymentURL = result.data?.paymentUrl ?? result.data?.gatewayResponse?.order?.url {
                    self.showPaymentGateway(url: paymentURL)
                } else {
                    self.showLottiePopup(title: result.message)
                }
            }
            .store(in: &cancellables)
        
        viewModel.validationPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] error in
                guard let self = self else { return }
                self.show(errorMessage: error.localizedDescription)
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    
    //MARK: - Actions -

    @IBAction func didTapCharge(_ sender: UIButton) {
        let amount = walletChargeTextField.txtField.text
        viewModel.validateAmount(amount: amount)
    }
}


//MARK: - Routes -
extension WalletChargeVC {

    func showPaymentGateway(url: String) {
        let vc = PaymentWebViewController()
        vc.urlString = url
        vc.onPaymentAccepted = { [weak self] in
            guard let self = self else { return }
            delegate?.didChargeWallet()
            pop()
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    func showLottiePopup(title: String){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title)
        vc.onPopupHidden = { [weak self] in
            guard let self = self else { return }
            delegate?.didChargeWallet()
            pop()
        }
    }
}

//MARK: - Delegate Protocol -

protocol WalletChargeProtocol : AnyObject {
    func didChargeWallet()
}
