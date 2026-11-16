//
//  OrderReasonSelectionView.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import UIKit

class OrderReasonSelectionView: BaseViewController {

    //MARK: - Outlets -
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView : TableViewContentSized!
    @IBOutlet weak var titleLabel: UILabel!
    
    //MARK: - Properties -
    
    private var selectedIndex: IndexPath?
    var selectedReason : String?
    var reasonsList : [CancelReasonsModel] = []
    var delegate : OrderReasonSelectionProtocol?
    var type : OrderReasonSelectionType = .cancelOrder
    
    //MARK: - Initializer  -
    
    init() {
        super.init(nibName: "OrderReasonSelectionView", bundle: nil)
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
        configureTableView()
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
    
    func hide(isDelegate: Bool){
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false){
                if isDelegate {
                    self.delegate?.didSelectReson(reason: self.selectedReason ?? "", type: self.type)
                }
            }
            self.removeFromParent()
        }
    }
    
    func getDataSource(reasonsList : [CancelReasonsModel], type :OrderReasonSelectionType ){
        titleLabel.text = type.title
        self.type = type
        self.reasonsList = reasonsList
        tableView.reloadData()
    }
        
    //MARK: - Actions -
    
    @IBAction func confirmlBtnTapped(_ sender: UIButton) {
        guard let selectedReason = selectedReason else {
            self.show(errorMessage : ValidationError.unselectedCancelReason.localizedDescription)
            return
        }
        self.hide(isDelegate: true)
    }
    
    @objc private func onBackViewTapped() {
        self.hide(isDelegate: false)
    }
}

//MARK: - TableView Configurations -
extension OrderReasonSelectionView : UITableViewDataSource , UITableViewDelegate {
    
    func configureTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: OrderReasonSelectionCell.self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reasonsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: OrderReasonSelectionCell.self, for: indexPath)
        let item = reasonsList[indexPath.row]
        if item.isSelected {
            selectedIndex = indexPath
        }
        cell.setupCell(model: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if let selectedIndex = selectedIndex {
                reasonsList[selectedIndex.row].isSelected = false
                selectedReason = nil
            }
            reasonsList[indexPath.row].isSelected = true
            selectedIndex = indexPath
        selectedReason =  reasonsList[indexPath.row].reason
        tableView.reloadData()
    }
}


//MARK: - Delegate Protocol -
protocol OrderReasonSelectionProtocol : AnyObject {
    func didSelectReson(reason: String , type : OrderReasonSelectionType)
}
