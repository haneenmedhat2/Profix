//
//  SearchProvidersVC.swift
//  Profix
//
//  Created by Haneen on 06/01/2026.
//

import UIKit
import Combine

class SearchProvidersVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    
    //MARK: - Properties -
    
    var viewModel : SearchProvidersVMProtocol
    
    //MARK: - Initializer -
    
    init(viewModel : SearchProvidersVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "SearchProvidersVC", bundle: nil)
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
        self.title = "search_results".localized
        bindToViewModel()
        configureCollectionView()
        viewModel.searchDelegates()
        searchTextField.addTarget(self, action: #selector(searchChanged(_:)), for: .editingChanged)
    }
    
    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        
        viewModel.delegatesPublisher
            .sinkOnMain{ [weak self] _ in
                guard let self = self else { return }
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        
        viewModel.searchSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    viewModel.searchQuery = nil
                } else {
                    viewModel.searchQuery = text
                }
                viewModel.searchDelegates()
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -
    
    @objc private func searchChanged(_ textField: UITextField) {
        viewModel.searchSubject.send(textField.text ?? "")
    }
}

//MARK: - CollectionView Configurations -
extension SearchProvidersVC : UICollectionViewDelegate ,UICollectionViewDataSource {
    
    func configureCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType:DelegateCell.self)
        collectionView.register(EmptyStateCell.self, forCellWithReuseIdentifier: "EmptyStateCell")
        
        let layout = UICollectionViewCompositionalLayout { section , environment in
            return self.providersSection(isEmpty: self.viewModel.delegates.isEmpty)
        }
        collectionView.setCollectionViewLayout(layout, animated: true)
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
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  viewModel.delegates.isEmpty ? 1 :  viewModel.delegates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !viewModel.delegates.isEmpty,
              viewModel.delegates.indices.contains(indexPath.row) else { return }
        let item = viewModel.delegates[indexPath.row]
        goToDelegateDetails(delegateId: item.id ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(collectionView.cellForItem(at: indexPath) is EmptyStateCell)
    }
}

//MARK: - Routes -

extension SearchProvidersVC {
    func goToDelegateDetails(delegateId : Int){
        let vc = ProviderDetailsVC(
            viewModel: ProviderDetailsVM(delegateId: delegateId, categoryId: viewModel.mainCategoryId),
            categoryId: viewModel.mainCategoryId
        )
        push(vc)
    }
}
