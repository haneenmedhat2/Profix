//
//  CustomerReviewVC.swift
//  Profix
//
//  Created by Haneen on 08/01/2026.
//

import UIKit
import Combine

class CustomerReviewVC: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Properties -
    
    var viewModel : CustomerReviewVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : CustomerReviewVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "CustomerReviewVC", bundle: nil)
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
        self.title = "customer_reviews".localized
        view.isHidden = true
        bindToViewModel()
        configureCollectionView()
        viewModel.delegateReviewsRequest()
    }
    
    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        
        viewModel.delegateReviewsPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                view.isHidden = false
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.reviewPublisher
            .compactMap { $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                self.showLottiePopup(title: result.message)
            }
            .store(in: &cancellables)

        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @IBAction func didTapAddRating(_ sender: UIButton) {
        switch UserMode.current {
        case .authenticated:
            showReviewPopup()
        case .guest:
            showGuestPopup()
        }
    }
}

//MARK: - CollectionView Configurations -

extension CustomerReviewVC : UICollectionViewDelegate ,UICollectionViewDataSource {
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: CustomerReviewCell.self)
        collectionView.register(EmptyStateCell.self, forCellWithReuseIdentifier: "EmptyStateCell")
        
        let layout = UICollectionViewCompositionalLayout { section , environment in
            switch section {
            default:
                return self.customerReviewsSection(isEmpty: self.viewModel.customerReviewsList.isEmpty)
            }
        }
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func customerReviewsSection(isEmpty: Bool) -> NSCollectionLayoutSection {
        let groupHeight: CGFloat = isEmpty ? collectionView.height : 80

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(groupHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(groupHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 8
        
        return section
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.customerReviewsList.isEmpty ? 1 : viewModel.customerReviewsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewModel.customerReviewsList.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyStateCell", for: indexPath) as! EmptyStateCell
            cell.configure(image: .appPlaceholder, message: "no_reviews".localized)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(with: CustomerReviewCell.self, for: indexPath)
            let item = viewModel.customerReviewsList[indexPath.row]
            cell.setupCell(model: item)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(collectionView.cellForItem(at: indexPath) is EmptyStateCell)
    }
}

//MARK: - Routes -
extension CustomerReviewVC {
    
    func showReviewPopup(){
        let pop = ProviderRatingPopup()
        pop.delegate = self
        pop.appear(sender: self)
    }
    
    func showLottiePopup(title: String){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title, type: .normal)
    }
    
    func showGuestPopup(){
        let vc = GuestLoginPopup()
        vc.appear(sender: self)
    }
}

//MARK: - Delegation -
extension CustomerReviewVC : RatingPopupProtocol{
    func didTapConfirm(rate: Double, comment: String?) {
        viewModel.createReview(model: CustomerReviewModel(orderId: nil, secondUserId: viewModel.delegateId, rate: rate, comment: comment))
    }
}
