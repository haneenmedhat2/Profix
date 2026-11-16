//
//  FilterPopup.swift
//  Profix
//
//  Created by Haneen on 05/01/2026.
//

import UIKit
import Combine

class FilterPopup: BaseViewController {

    //MARK: - Outlets -
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var collectionView: CollectionViewContentSized!
    @IBOutlet weak var cityTextField: PickerFieldView!
    
    //MARK: - Properties -
    
    var viewModel : FilterPopupVM
    var delegate : FilterPopupProtocol?

    //MARK: - Initializer  -
    
    init(viewModel : FilterPopupVM) {
        self.viewModel = viewModel
        super.init(nibName: "FilterPopup", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfiguration()
    }
    
    //MARK: - Initial Configuration -
    
    func initialConfiguration(){
        configView()
        configureCollectionView()
        bindViewModel()
        cityTextField.delegate = self
        cityTextField.txtField.text = viewModel.selectedCity?.pickerName
    }
    
    //MARK: - ViewModel Binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        
        viewModel.cityPublisher
            .dropFirst()
            .sinkOnMain { [weak self] _ in
                guard let self = self else { return }
                self.showCityPopup()
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }
    
    //MARK: - View Configuration -
    
    func configView(){
        self.view.backgroundColor = .clear
        self.backView.backgroundColor  = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.contentView.alpha = 0
        self.contentView.layer.cornerRadius = 12
        contentView.isUserInteractionEnabled = true
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(onBackViewTapped))
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(backTap)
    }

    func appear(sender:UIViewController){
        sender.present(self, animated: false){
            self.show()
        }
    }
    
    func show(){
        UIView.animate(withDuration: 1, delay: 0.1){
            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    
    func hide(){
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false){
            }
            self.removeFromParent()
        }
    }
    
    func showCityPopup(){
        let popup = PickerListPopup()
        popup.pickerList = viewModel.cities
        popup.selectedItem = viewModel.selectedCity
        
        popup.onItemSelected = { [weak self] item in
            guard let self = self else { return }
            self.viewModel.selectedCity = item
            self.cityTextField.txtField.text = item?.pickerName
        }
        popup.appear(sender: self)
    }

    //MARK: - Actions -
    
    @IBAction func confirmlBtnTapped(_ sender: UIButton) {
        let state = FilterState(
            selectedRate: viewModel.selectedRate, selectedCity: viewModel.selectedCity
        )
        delegate?.didApplyFilter(state:state)
        self.hide()
    }
    
    @objc private func onBackViewTapped() {
        self.hide()
    }
}

//MARK: - Collection View Configuration -

extension FilterPopup : UICollectionViewDelegate , UICollectionViewDataSource {
    
    private func configureCollectionView(){
        let layout = UICollectionViewFlowLayout()
        
        let screenWidth = UIScreen.main.bounds.width
        let size = (screenWidth / 2) - 24
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: size, height: 40)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: ChooseRateCell.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.rateList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with:  ChooseRateCell.self, for: indexPath)
        let item = viewModel.rateList[indexPath.row]
        let isSelected = item == viewModel.selectedRate
        cell.configureCell(title: item.title)
        cell.radioBtn.isOn = isSelected
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.selectedRate == viewModel.rateList[indexPath.row] {
            viewModel.selectedRate = nil
        } else {
            viewModel.selectedRate = viewModel.rateList[indexPath.row]
        }
        collectionView.reloadData()
    }
}

//MARK: - Delegate Confirmation -

extension FilterPopup : PickerFieldViewDelegate {
    func pickerFieldViewDidTap(_ view: PickerFieldView) {
        if viewModel.cities.isEmpty {
            viewModel.getCities()
        } else {
            showCityPopup()
        }
    }
}

//MARK: - Delegaion Protocol -

protocol FilterPopupProtocol : AnyObject {
    func didApplyFilter(state : FilterState)
}
