//
//  ServicesVC.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import UIKit
import Combine

class ServicesVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var confirmButton: MainButton!
    
    //MARK: - Properties -
    
    var viewModel : ServicesVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : ServicesVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "ServicesVC", bundle: nil)
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
    
    func initialConfiguration(){
        self.title = "services".localized
        view.isHidden = true
        bindToViewModel()
        configureCollectionView()
        viewModel.allServicesRequest()
    }
    
    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        viewModel.servicesPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                view.isHidden = false
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.hasSelectedServicePublisher
            .sinkOnMain { [weak self] hasSelection in
                guard let self = self else { return }
                self.confirmButton.isEnabled = hasSelection
                self.confirmButton.alpha = hasSelection ? 1 : 0.5
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @IBAction func didTapConfirm(_ sender: UIButton) {
        switch UserMode.current {
        case .authenticated:
            showLottiePopup(title: "service_added_success".localized)
        case .guest:
            showGuestPopup()
        }
    }
}

//MARK: - CollectionView Configurations -

extension ServicesVC : UICollectionViewDelegate ,UICollectionViewDataSource {
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: ServicesCell.self)
        
        let layout = UICollectionViewCompositionalLayout { section , environment in
            switch section {
            default:
                return self.servicesSection()
            }
        }
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func servicesSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(56)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 12
        
        return section
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  viewModel.services.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: ServicesCell.self, for: indexPath)
        let item = viewModel.services[indexPath.row]
        cell.mode = .full
        cell.setupCell(service: item)
        cell.updateCellSelection(isSelected: item.isSelected)
        cell.updateQuantity(item.quantity)
        cell.onIncrement = { [weak self] in
            self?.viewModel.incrementQuantity(at: indexPath.row)
        }
        cell.onDecrement = { [weak self] in
            self?.viewModel.decrementQuantity(at: indexPath.row)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.toggleService(at: indexPath.row)
    }
}

//MARK: - Routes -

extension ServicesVC {
    func showLottiePopup(title: String){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.delegate = self
        vc.setupView(title: title, type: .action)
    }
    
    func goToCompleteReservations(){
        let vc = CompleteBookingVC(viewModel: CompleteBookingVM(model: viewModel.buildOrderContext()))
        push(vc, animated: true)
    }
    
    func showGuestPopup(){
        let vc = GuestLoginPopup()
        vc.appear(sender: self)
    }
}

//MARK: - Delegation -

extension ServicesVC : LottiePopupProtocol {
    func didTapFirstAction() {
        goToCompleteReservations()
    }
}
