//
//  OrderSummary.swift
//  Profix
//
//  Created by Haneen on 15/01/2026.
//

import UIKit
import Combine

class OrderSummary: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var collectionView: CollectionViewContentSized!
    @IBOutlet weak var problemDescView: ProblemDescView!
    @IBOutlet weak var geographicLocationView: GeographicLocationView!
    @IBOutlet weak var orderSummaryView: OrderSummaryView!
    
    //MARK: - Properties -
    
    var viewModel : OrderSummaryVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : OrderSummaryVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "OrderSummary", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfiguration()
    }
    
    //MARK: - Initial Setup -
    
    func initialConfiguration(){
        self.title = "order_summary".localized
        setupViews()
        bindViewModel()
        configureCollectionView()
        viewModel.orderEnquiryRequest()
    }
    
    func setupViews(){
        problemDescView.getDataSource(problemDesc: viewModel.orderModel.description ?? "", imageList: viewModel.getProblemDescImages(),type: .createOrder)
        problemDescView.delegate = self
        
        geographicLocationView.setupData(location: viewModel.orderModel.address ?? "", lat: viewModel.orderModel.lat ?? 0.0, long: viewModel.orderModel.long ?? 0.0, type: .createOrder)
        
    }
    
    //MARK: - ViewModel binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.createOrderPublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                let message = result.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "order_created_success".localized : result.message
                self.showPopup(title: message, orderId: result.data?.orderId)
            }
            .store(in: &cancellables)
        
        viewModel.orderEnquiryPublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.collectionView.reloadData()
                self.orderSummaryView.getDataSource(model: result.data, title: "order_summary".localized)
            }
            .store(in: &cancellables)

        viewModel.validationPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.show(errorMessage: result.localizedDescription)
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @IBAction func didTapConfirmOrder(_ sender: UIButton) {
        viewModel.createOrderRequest()
    }
}

//MARK: - CollectionView Configuration -

extension OrderSummary : UICollectionViewDataSource, UICollectionViewDelegate , UICollectionViewDelegateFlowLayout{
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: ServicesCell.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return viewModel.servicesList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(with: ServicesCell.self, for: indexPath)
            let item = viewModel.servicesList[indexPath.row]
            cell.mode = .simple
            cell.setupCell(service: item, displayName: item.name)
            cell.showExecutionCount(item.quantity)
            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.width
        return CGSize(width: width, height: 56)
    }
}

//MARK: - Routes -

extension OrderSummary {
    
    func showPopup(title: String, orderId: Int?){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title)
        vc.onPopupHidden = { [weak self] in
             guard let self = self else { return }
                let tabBar  = AppTabBarController()
                tabBar.selectedIndex = 1
                AppHelper.changeWindowRoot(vc: tabBar)
                if let orderId {
                    tabBar.loadViewIfNeeded()
                    tabBar.routeToOrder(orderId)
                }
            }
        }
}

//MARK: - Delegation -

extension OrderSummary : ProblemDescViewDelegate {
    func didSelectImage(_ image: ProblemDescImageType) {
        let vc = ImageViewerVC(viewModel: ImageViewerVM(image: image))
        vc.appear(sender: self)
    }
}
