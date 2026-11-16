//
//  MainCategoryVC.swift
//  Profix
//
//  Created by Haneen on 01/01/2026.
//

import UIKit
import Combine

class MainCategoryVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Properties -
    
    var viewModel : MainCategoryVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : MainCategoryVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "MainCategoryVC", bundle: nil)
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
        self.title = viewModel.categoryModel.name
        bindToViewModel()
        configureCollectionView()
        viewModel.subcategoryRequest()
        configureFilterButton()
    }
    
    func configureFilterButton(){
        let filterBtn = UIButton()
        filterBtn.setImage(UIImage(resource: .filterBtn), for: .normal)
        filterBtn.addTarget(self, action: #selector(didTapFilter), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: filterBtn)
    }
    
    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        
        viewModel.subcategoriesPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.delegatesPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @objc func didTapFilter(){
        showFilterPopup()
    }
}

//MARK: - CollectionView Configurations -
extension MainCategoryVC : UICollectionViewDelegate ,UICollectionViewDataSource {
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(EmptyStateCell.self, forCellWithReuseIdentifier: "EmptyStateCell")
        collectionView.register(cellType: SubCategoryCell.self)
        collectionView.register(cellType:SearchCell.self)
        collectionView.register(cellType:DelegateCell.self)
        
        let layout = UICollectionViewCompositionalLayout { section , environment in
            switch section {
            case 0:
                return self.subCategorySection()
            case 1:
                return self.searchSection()
            case 2:
                return self.providersSection(isEmpty: self.viewModel.delegates.isEmpty)
            default:
                return self.subCategorySection()
            }
        }
        layout.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.elementKind)
        collectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func subCategorySection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize( widthDimension: .estimated(110), heightDimension: .absolute(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        item.contentInsets = NSDirectionalEdgeInsets( top: 8,leading: 0,bottom: 8,trailing: 0)

        let groupSize = NSCollectionLayoutSize( widthDimension: .estimated(110),heightDimension: .absolute(56))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8

        section.contentInsets = NSDirectionalEdgeInsets( top: 8,leading: 16, bottom: 8, trailing: 16)

        let background = NSCollectionLayoutDecorationItem.background(
            elementKind: SectionBackgroundView.elementKind
        )
        background.contentInsets = NSDirectionalEdgeInsets( top: 8,leading: 8,bottom: 8,trailing: 8)
        section.decorationItems = [background]

        return section
    }
    
    func searchSection()-> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(42))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(42))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        return section
    }
    
    func providersSection(isEmpty: Bool) -> NSCollectionLayoutSection {
        let groupHeight: CGFloat = isEmpty ? 240 : 70

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        section.interGroupSpacing = 8

        return section
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return viewModel.subcategories.count
        case 1:
            return 1
        case 2:
            return viewModel.delegates.isEmpty ? 1 :  viewModel.delegates.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(with: SubCategoryCell.self, for: indexPath)
            let item = viewModel.subcategories[indexPath.row]
            let isSelected = indexPath == viewModel.selectedIndex
            cell.setupCell(model: item, isSelected : isSelected)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(with: SearchCell.self, for: indexPath)
            return cell
        case 2:
            if viewModel.delegates.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyStateCell", for: indexPath) as! EmptyStateCell
                cell.configure(image: .appPlaceholder, message: "no_providers_in_category".localized)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(with: DelegateCell.self, for: indexPath)
                let item = viewModel.delegates[indexPath.row]
                cell.setupCell(model: item)
                return cell
            }
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            viewModel.selectedIndex = indexPath
            let item = viewModel.subcategories[indexPath.row]
            viewModel.model.subcategoryId = item.id ?? 0
            viewModel.resetData()
            viewModel.allDelegatesRequest()
        case 1:
            goToSearchAll()
        case 2:
            guard !viewModel.delegates.isEmpty else { return }
            let item = viewModel.delegates[indexPath.row]
            goToDelegateDetails(delegateId: item.id ?? 0)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(collectionView.cellForItem(at: indexPath) is EmptyStateCell)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 2, !viewModel.delegates.isEmpty else { return }
        if indexPath.row == viewModel.delegates.count - 1,
           !viewModel.isLastPage {
            viewModel.allDelegatesRequest()
        }
    }
}

//MARK: - Routes -

extension MainCategoryVC {
    func goToSearchAll(){
        let vc = SearchProvidersVC(viewModel: SearchProvidersVM(mainCategoryId: viewModel.categoryModel.id, subCategoryId: viewModel.model.subcategoryId))
        vc.hidesBottomBarWhenPushed = true
        push(vc)
    }
    
    func goToDelegateDetails(delegateId : Int){
        let vc = ProviderDetailsVC(
            viewModel: ProviderDetailsVM(delegateId: delegateId, categoryId: viewModel.categoryModel.id),
            categoryId: viewModel.categoryModel.id
        )
        push(vc)
    }
    
    func showFilterPopup(){
        let popup = FilterPopup(viewModel: FilterPopupVM(state: viewModel.filterState))
        popup.delegate = self
        popup.appear(sender: self)
    }
}

//MARK: - Delegate Confirmation -

extension MainCategoryVC :FilterPopupProtocol {
    func didApplyFilter(state: FilterState) {
        viewModel.applyFilter(state: state)
    }
}
