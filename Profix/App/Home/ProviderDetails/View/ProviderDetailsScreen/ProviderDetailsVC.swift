//
//  ProviderDetailsVC.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import UIKit
import Combine

class ProviderDetailsVC: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Properties -
    
    var viewModel : ProviderDetailsVMProtocol
    private let categoryId: Int

    private var filteredServices: [Services] {
        viewModel.servicesList.filter { $0.categoryId == categoryId }
    }
    
    //MARK: - Initializer -
    
    init(viewModel: ProviderDetailsVMProtocol, categoryId: Int) {
        self.viewModel = viewModel
        self.categoryId = categoryId
        super.init(nibName: "ProviderDetailsVC", bundle: nil)
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
        self.title = "provider_profile".localized
        view.isHidden = true
        bindToViewModel()
        configureCollectionView()
        viewModel.delegateDetailsRequest()
        configureComplaintsButton()
    }
    
    func configureComplaintsButton(){
        let complaintsBtn = UIButton()
        complaintsBtn.setImage(UIImage(resource: .complaintsBtn), for: .normal)
        complaintsBtn.addTarget(self, action: #selector(didTapComplaint), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: complaintsBtn)
    }
    
    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        viewModel.providerDetailsPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                view.isHidden = false
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @objc func didTapComplaint(){
        switch UserMode.current {
        case .authenticated:
            goToComplaints()
            
        case .guest:
            showGuestPopup()
        }
    }
}

//MARK: - CollectionView Configurations -

extension ProviderDetailsVC : UICollectionViewDelegate ,UICollectionViewDataSource {
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(EmptyStateCell.self, forCellWithReuseIdentifier: "EmptyStateCell")
        collectionView.register(cellType: ProviderDetailsCell.self)
        collectionView.register(cellType: ServicesCell.self)
        collectionView.register(cellType: PreviousWorkCell.self)
        collectionView.register(cellType: CustomerReviewCell.self)
        collectionView.register(CollectionHeaderView.self,
                                forSupplementaryViewOfKind: CollectionHeaderView.elementKind,
                                withReuseIdentifier: CollectionHeaderView.headerIdentifier)
        
        let layout = UICollectionViewCompositionalLayout { section , environment in
            switch section {
            case 0:
                return self.providerDetailsSection()
            case 1:
                return self.servicesSection(isEmpty: self.filteredServices.isEmpty)
            case 2:
                return self.previousWorkSection(isEmpty: self.viewModel.previousWorkList.isEmpty)
            case 3:
                return self.customerReviewsSection(isEmpty: self.viewModel.customerReviewsList.isEmpty)
            default:
                return self.providerDetailsSection()
            }
        }
        
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    
    func providerDetailsSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(280)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(280)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
        return section
    }
    
    func servicesSection(isEmpty: Bool) -> NSCollectionLayoutSection {
        let groupHeight: CGFloat = isEmpty ? 160 : 56

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(groupHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(groupHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 8
        
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)), elementKind: CollectionHeaderView.elementKind, alignment: .top)
        ]
        
        return section
    }
    
    func previousWorkSection(isEmpty: Bool) -> NSCollectionLayoutSection {
        let groupHeight: CGFloat = isEmpty ? 160 : 110

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(groupHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(groupHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 8
        
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)), elementKind: CollectionHeaderView.elementKind, alignment: .top)
        ]
        
        return section
    }
    
    func customerReviewsSection(isEmpty: Bool) -> NSCollectionLayoutSection {
        let groupHeight: CGFloat = isEmpty ? 160 : 80

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 8
        
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)), elementKind: CollectionHeaderView.elementKind, alignment: .top)
        ]
        
        return section
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return filteredServices.isEmpty ? 1 : min(2, filteredServices.count)
        case 2:
            return viewModel.previousWorkList.isEmpty ? 1 : viewModel.previousWorkList.count
        case 3:
            return viewModel.customerReviewsList.isEmpty ? 1 : min(1, viewModel.customerReviewsList.count)
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(with: ProviderDetailsCell.self, for: indexPath)
            guard let provider = viewModel.providerDetails else { return cell }
            cell.setupCell(provider: provider)
            return cell
            
        case 1:
            if filteredServices.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyStateCell", for: indexPath) as! EmptyStateCell
                cell.configure(image: .appPlaceholder, message: "no_services".localized)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(with: ServicesCell.self, for: indexPath)
                let item = filteredServices[indexPath.row]
                cell.mode = .simple
                cell.setupCell(service: item)
                return cell
            }
            
        case 2:
            if viewModel.previousWorkList.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyStateCell", for: indexPath) as! EmptyStateCell
                cell.configure(image: .appPlaceholder, message: "no_previous_work".localized)
                return cell
            }  else {
                let cell = collectionView.dequeueReusableCell(with: PreviousWorkCell.self, for: indexPath)
                let item = viewModel.previousWorkList[indexPath.row]
                cell.setupCell(model: item)
                return cell
            }
            
        case 3:
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
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 2:
            guard !viewModel.previousWorkList.isEmpty,
                  viewModel.previousWorkList.indices.contains(indexPath.row) else { return }
            let item = viewModel.previousWorkList[indexPath.row]
            let vc = ImageViewerVC(viewModel: ImageViewerVM(image: .remote(item.image ?? "")))
            vc.appear(sender: self)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(collectionView.cellForItem(at: indexPath) is EmptyStateCell)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        var title = ""
        var headerType : HeaderTypes = .services
        switch indexPath.section {
        case 1:
            title = "services".localized
            headerType = .services
        case 2:
            title = "previous_works".localized
            headerType = .previousWorks
        case 3:
            title = "customer_reviews".localized
            headerType = .customerReviews
        default:
            break
        }
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: CollectionHeaderView.elementKind,
            withReuseIdentifier: CollectionHeaderView.headerIdentifier,
            for: indexPath
        ) as! CollectionHeaderView
        
        header.configure(title: title, headerType: headerType)
        header.delegate = self
        return header
    }
}

//MARK: - Routes -

extension ProviderDetailsVC {
    func goToComplaints() {
        let tabBar = AppTabBarController()
        tabBar.selectedIndex = 3

        AppHelper.changeWindowRoot(vc: tabBar)
        if let moreNav = tabBar.viewControllers?[3] as? UINavigationController {
            let vc = AddNewComplaintVC(viewModel: AddNewComplaintsVM())
            vc.hidesBottomBarWhenPushed = true
            moreNav.pushViewController(vc, animated: true)
        }
    }
    
    func goToServices(){
        let vc = ServicesVC(
            viewModel: ServicesVM(
                delegateId: viewModel.delegateId,
                categoryId: categoryId,
                dayPeriods: viewModel.providerDetails?.dayPeriods
            )
        )
        push(vc, animated: true)
    }
    
    func goToCustomerReviews(){
        let vc = CustomerReviewVC(viewModel: CustomerReviewVM(delegateId: viewModel.delegateId))
        push(vc, animated: true)
    }
    
    func showGuestPopup(){
        let vc = GuestLoginPopup()
        vc.appear(sender: self)
    }
}

//MARK: - Delegation -

extension ProviderDetailsVC : HeaderViewDelegate {
    func didTapShowAll(headerType: HeaderTypes?) {
        switch headerType {
        case .services:
            goToServices()
        case .customerReviews:
            goToCustomerReviews()
        default:
            break
        }
    }
}
