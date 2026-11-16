//
//  HomeVC.swift
//  Profix
//
//  Created by Haneen on 21/12/2025.
//

import UIKit
import Combine
import CoreLocation

class HomeVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK: - Properties -
    
    let viewModel : HomeVMProtocol
    let refreshController = UIRefreshControl()
    private let addressBarView = AddressBarView()
    private var sitePhone: String?

    private lazy var callAdminButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .main
        button.tintColor = .white
        button.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCallAdmin), for: .touchUpInside)
        return button
    }()

    private lazy var callAdminLabel: UILabel = {
        let label = UILabel()
        label.text = "technical_support".localized
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .main
        label.textAlignment = .center
        return label
    }()

    private lazy var callAdminContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [callAdminButton, callAdminLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    //MARK: - Initializer -
    
    init(viewModel : HomeVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "HomeVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad(){
        super.viewDidLoad()
        initialConfiguration()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UserDefaults.languageChanged {
            UserDefaults.languageChanged = false
            viewModel.changeLanguageRequest()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !(Session.isGuest ?? false) {
            NotificationCountManager.shared.refresh()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Initial Setup -
    
    func initialConfiguration(){
        view.isHidden = true
        viewModel.homeRequest()
        viewModel.getSitePhone()
        configureCollectionView()
        setupCallAdminButton()
        bindToViewModel()
        setupNotificationButton()
        handleAddress()
        setupRefresh()
    }

    private func setupCallAdminButton() {
        callAdminContainer.isHidden = true
        view.addSubview(callAdminContainer)

        NSLayoutConstraint.activate([
            callAdminButton.widthAnchor.constraint(equalToConstant: 56),
            callAdminButton.heightAnchor.constraint(equalToConstant: 56),
            callAdminContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            callAdminContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func didTapCallAdmin() {
        guard let phone = sitePhone, !phone.isEmpty else { return }
        let sanitized = phone.replacingOccurrences(of: " ", with: "")
        AppHelper.openUrl("tel://\(sanitized)")
    }
    
    func setupRefresh(){
        refreshController.addTarget(self, action: #selector(didRefreshHome), for: .valueChanged)
        collectionView.refreshControl = refreshController
    }
    
    //MARK: - Address Setup -
    
    func handleAddress(){
        switch UserMode.current {
        case .authenticated:
            setupAddressBar()
            setupUserLocation()
        case .guest:
            self.title = "home".localized
            setupUserLocation()
        }
    }
    
    func setupAddressBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addressBarView)
    }
    
    func setupUserLocation() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        let hasLocationAccess = authorizationStatus == .authorizedAlways ||
            authorizationStatus == .authorizedWhenInUse

        if hasLocationAccess, let cachedLocation = UserDefaults.currentLocation {
            updateAddress(cachedLocation.desc)
            return
        }

        AppLocationManager.shared.requestLocation { [weak self] address in
            guard let address else { return }
            self?.updateAddress(address.desc)
        }
    }
    
    func updateAddress(_ address: String) {
        addressBarView.updateAddress(address)
    }
    
    //MARK: - ViewModel Binding -

    func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        
        viewModel.homePublisher
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                view.isHidden = false
                self.collectionView.reloadData()
                self.refreshController.endRefreshing()
            }
            .store(in: &cancellables)

        viewModel.sitePhonePublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] phone in
                guard let self = self else { return }
                self.sitePhone = phone
                self.callAdminContainer.isHidden = phone.isEmpty
            }
            .store(in: &cancellables)

        error(viewModel.errorPublisher)
    }
    
    //MARK: - Action -

    @objc func didRefreshHome() {
        AppLocationManager.shared.requestLocation { [weak self] address in
            guard let self = self else { return }
            guard let address else {
                self.refreshController.endRefreshing()
                self.viewModel.homeRequest()
                return
            }
            
            self.updateAddress(address.desc)
            self.viewModel.homeRequest()
        }
    }
}

//MARK: - Collection View Configurations -

extension HomeVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func configureCollectionView() {
        collectionView.setCollectionViewLayout(makeLayout(), animated: false)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HomeBannerCollectionCell.self,
                                forCellWithReuseIdentifier: HomeBannerCollectionCell.reuseIdentifier)
        collectionView.register(HomeCategoryCollectionCell.self,
                                forCellWithReuseIdentifier: HomeCategoryCollectionCell.reuseIdentifier)
        collectionView.register(HomeSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: HomeSectionHeaderView.reuseIdentifier)
    }

    func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .banner:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(140)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                return layoutSection

            case .categories:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(152)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(28)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                layoutSection.boundarySupplementaryItems = [header]
                return layoutSection
            }
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .banner:
            return viewModel.ads.isEmpty ? 0 : 1
        case .categories:
            return viewModel.categoriesList.count
        case .none:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section) {
        case .banner:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeBannerCollectionCell.reuseIdentifier,
                for: indexPath
            ) as! HomeBannerCollectionCell
            cell.configure(ads: viewModel.ads)
            return cell

        case .categories:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeCategoryCollectionCell.reuseIdentifier,
                for: indexPath
            ) as! HomeCategoryCollectionCell
            cell.configure(model: viewModel.categoriesList[indexPath.item])
            return cell

        case .none:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .categories else { return }
        let category = viewModel.categoriesList[indexPath.item]

        if category.status == .pending {
            show(successMessage: "category_coming_soon".localized)
            return
        }

        goToMainCategory(model: category)
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: HomeSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! HomeSectionHeaderView
        header.configure(title: "main_categories".localized)
        return header
    }
}
//MARK: - Routes -

extension HomeVC {
    func goToMainCategory(model : HomeCategory){
        let vc = MainCategoryVC(viewModel: MainCategoryVM(categoryModel: model))
        vc.hidesBottomBarWhenPushed = true
        push(vc)
    }
}
