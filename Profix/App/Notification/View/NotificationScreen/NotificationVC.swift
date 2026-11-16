//
//  NotificationVC.swift
//  Profix
//
//  Created by Haneen on 09/12/2025.
//

import UIKit
import Combine

class NotificationVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var tableView: TableViewContentSized!
    @IBOutlet weak var deleteBtnStackView: UIStackView!
    
    //MARK: - Properties -
    
    var viewModel : NotificationVM
    let refreshController = UIRefreshControl()
    
    //MARK: - Initializer -
    
    init(viewModel :NotificationVM){
        self.viewModel = viewModel
        super.init(nibName: "NotificationVC", bundle: nil)
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
    
    private func initialConfiguration(){
        self.title = "notifications".localized
        NotificationCountManager.shared.markAllAsRead()
        view.isHidden = true
        viewModel.getNotification()
        configureTableView()
        bindToViewModel()
        setupRefreshControl()
    }
    
    func setupRefreshControl(){
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
    }

    
    //MARK: - ViewModel binding -
    
    private func bindToViewModel(){
        loading(viewModel.isLoadingPublisher)
        
        viewModel.notificationPublisher
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.refreshController.endRefreshing()
                view.isHidden = false
                self.deleteBtnStackView.isHidden = viewModel.isDeleteAllHidden
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.deleteNotificationPublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                show(successMessage: result.message)
            }
            .store(in: &cancellables)
        
        viewModel.deleteAllPublisher
            .compactMap{ $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                show(successMessage: result.message)
            }
            .store(in: &cancellables)
        
        error(viewModel.errorPublisher)
    }

    //MARK: - Action -
    
    @objc func refreshData(){
        viewModel.resetData()
        viewModel.getNotification()
    }
    
    @IBAction func didTapDeleteAll(_ sender: UIButton) {
        showDoubleActionPopup()
    }
}

//MARK: - TableView Configutations -

extension NotificationVC : UITableViewDelegate , UITableViewDataSource {
    
    private func configureTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: NotificationCell.self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.setPlaceholder(isEmpty: viewModel.notificationList.isEmpty , separator: .none, style: .notifications)
        return viewModel.notificationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: NotificationCell.self, for: indexPath)
        cell.delegate = self
        let item = viewModel.notificationList[indexPath.row]
        cell.setupCell(model: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.notificationList[indexPath.row]
        switch item.notificationType {

        case .delegateAcceptDate ,.delegateAcceptedOffer , .delegateCreatedInvoice , .delegateFinishedOrder, .delegateRefuseDate, .delegateRefusedOrder , .orderIntransit, .scheduledOrderReminder ,  .scheduledOrderLateCancelFee , .scheduledOrderLateEditFee , .autoCancelNoDelegateResponse, .orderIsPaid:
            goToOrderDetails(orderId : item.orderId ?? 0)
            
        case .ticketReply,.ticketInprogress:
            goToComplaintDetails(ticketId : item.ticketId ?? 0)
           
        case .refundOrder:
            goToWallet()
            
        case .clientUpdated:
            goToProfile()
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.viewModel.notificationList.count - 1,
           !viewModel.isLastPage {
            viewModel.getNotification()
        }
    }
}

//MARK: - Routes -
extension NotificationVC {
    
    func goToOrderDetails(orderId : Int){
        let vc = OrderDetailsVC(viewModel: OrderDetailsVM(orderId: orderId))
        push(vc)
    }
    
    func goToComplaintDetails(ticketId : Int){
        let vc = ComplaintsDetailsVC(viewModel: ComplaintsDetailsVM(id: ticketId))
        push(vc)
    }

    func goToWallet(){
        let vc = WalletVC(viewModel: WalletVM())
        push(vc)
    }
    
    func goToProfile(){
        let vc = ProfileVC(viewModel: ProfileVM())
        push(vc)
    }
    
    func showDoubleActionPopup(){
        let popup = DoubleActionPopupView()
        popup.appear(sender: self)
        popup.delegate = self
        popup.setupView(type: .deleteNotifications)
    }
}

//MARK: - Protocol Confirmation -

extension NotificationVC : NotificationCellProtocol,DoubleActionPopupProtocol {
    
    func didTapFirstAction() {
        viewModel.deleteAllNotifications()
    }
    
    func didTapDelete(notificationId: String) {
        viewModel.deleteNotificationRequest(notificationId: notificationId)
    }
}
