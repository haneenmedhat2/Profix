//
//  OrderDetailsVC.swift
//  Profix
//
//  Created by Haneen on 17/01/2026.
//

import UIKit
import Combine
import Kingfisher

class OrderDetailsVC: BaseViewController {
    
    //MARK: - Outlets -
    
    @IBOutlet weak var containerStackView: UIStackView!
    @IBOutlet weak var orderNotesView: UIView!
    @IBOutlet weak var orderNotesLabel: UILabel!
    @IBOutlet weak var providerView: ProviderView!
    @IBOutlet weak var orderDetailsView: OrderSummaryView!
    @IBOutlet weak var problemDescView: ProblemDescView!
    @IBOutlet weak var geograpgicLocationView: GeographicLocationView!
    @IBOutlet weak var orderSummryView: OrderSummaryView!
    @IBOutlet weak var cancellationView: ContextView!
    @IBOutlet weak var feedbackView: ContextView!
    
    //Buttons
    @IBOutlet weak var cancelOrderButton: UIButton!
    @IBOutlet weak var payNowButton: MainButton!
    @IBOutlet weak var editCancelStackView: UIStackView!
    @IBOutlet weak var rateServicebutton: MainButton!
    @IBOutlet weak var billButonsStackView: UIStackView!
    @IBOutlet weak var editTimeButton: MainButton!
    @IBOutlet weak var firstCancelStackView: UIStackView!
    
    //MARK: - Properties -
    
    var viewModel : OrderDetailsVMProtocol
    private let refreshControl = UIRefreshControl()
    private var hasShownPledge = false
    
    private var chatUIButton: UIButton!
    private var reportUIButton: UIButton!
    private var billUIButton: UIButton!
    private let paymentCountdownView = PaymentCountdownView()
    private let acceptanceCountdownView = PaymentCountdownView()
    private var isScreenVisible = false
    private let requestedServicesView = OrderSummaryView()
    
    //MARK: - Initializer -
    
    init(viewModel :OrderDetailsVMProtocol){
        self.viewModel = viewModel
        super.init(nibName: "OrderDetailsVC", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Life Cycle -
    
    override func viewDidLoad(){
        super.viewDidLoad()
        initialConfiguration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isScreenVisible = true
        if UIApplication.shared.applicationState == .active {
            viewModel.resumePaymentCountdown()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isScreenVisible = false
        viewModel.stopPaymentCountdown()
    }

    @objc private func appDidBecomeActive() {
        guard isScreenVisible else { return }
        viewModel.resumePaymentCountdown()
    }

    @objc private func appWillResignActive() {
        viewModel.stopPaymentCountdown()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .isOrderChanged, object: nil)
    }
    
    //MARK: - Initial Setup -
    
    func initialConfiguration(){
        containerStackView.insertArrangedSubview(paymentCountdownView, at: 0)
        containerStackView.insertArrangedSubview(acceptanceCountdownView, at: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(isOrderChanged), name: .isOrderChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        setupRequestedServicesView()
        bindViewModel()
        self.title = "order_details".localized
        view.isHidden = true
        setupRefreshControl()
        setupNavigationBar()
    }

    private func setupRequestedServicesView() {
        guard let orderDetailsIndex = containerStackView.arrangedSubviews.firstIndex(of: orderDetailsView) else { return }
        containerStackView.insertArrangedSubview(requestedServicesView, at: orderDetailsIndex + 1)
    }
    
    //MARK: - Navigation Bar Design -
        
    private func setupNavigationBar() {
        
        let chatButton = makeButton(
            image: UIImage(resource: .chat),
            action: #selector(didTapChatButton)
        )

        let reportButton = makeButton(
            image: UIImage(resource: .complaints),
            action: #selector(didTapReportButton)
        )

        let billButton = makeButton(
            image: UIImage(resource: .bill),
            action: #selector(didTapBillButton)
        )
        
        self.chatUIButton = chatButton
        self.reportUIButton = reportButton
        self.billUIButton = billButton
        
        let stack = UIStackView(arrangedSubviews: [
            chatButton,
            reportButton,
            billButton
        ])
        
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        
        let barItem = UIBarButtonItem(customView: stack)
        navigationItem.rightBarButtonItem = barItem
    }
    
    private func makeButton(image: UIImage, action: Selector) -> UIButton {
        
        let button = UIButton(type: .system)
        button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        return button
    }
    
    private func setupRefreshControl(){
        if let scrollView = containerStackView.superview as? UIScrollView {
            scrollView.alwaysBounceVertical = true
            refreshControl.addTarget(self, action: #selector(isOrderChanged), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }
    }
    
    //MARK: - ViewModel binding -
    
    private func bindViewModel() {
        loading(viewModel.isLoadingPublisher)
        viewModel.acceptanceCountdownPublisher
            .sinkOnMain { [weak self] state in
                let displayState = state.map {
                    PaymentCountdownState(
                        remainingSeconds: $0.remainingSeconds,
                        message: $0.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "acceptance_countdown_message".localized : $0.message
                    )
                }
                self?.acceptanceCountdownView.configure(state: displayState, showsZero: true)
            }
            .store(in: &cancellables)
        viewModel.paymentCountdownPublisher
            .sinkOnMain { [weak self] state in
                self?.paymentCountdownView.configure(state: state)
            }
            .store(in: &cancellables)
        viewModel.isLoadingPublisher
            .sinkOnMain { [weak self] isLoading in
                if !isLoading { self?.refreshControl.endRefreshing() }
            }
            .store(in: &cancellables)
        
        viewModel.orderDetailsPublisher
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                guard let result = result?.data?.order else { return }
                self.viewSetup(model: result)
                self.handleShowButtonsAndViews(model : result)
                self.handleShowPledge(model : result)
                view.isHidden = false
                self.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)
        
        viewModel.cancelReasonsPublisher
            .dropFirst()
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.showOrderReasonSelectionPopup(list : result)
            }
            .store(in: &cancellables)
        
        viewModel.cancelOrderPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                self.showLottiePopup(title: result.message, type: .cancelOrder)
            }
            .store(in: &cancellables)
        
        viewModel.paymentMethodsPublisher
            .dropFirst()
            .sinkOnMain { [weak self] list in
                guard let self = self else { return }
                self.showPaymentMethodPopup(paymentMethodsList :list)
            }
            .store(in: &cancellables)
        
        viewModel.payOrderPublisher
            .compactMap { $0 }
            .sinkOnMain { [weak self] result in
                guard let self = self else { return }
                if let paymentURL = result.response.data?.checkoutURL {
                    self.showPaymentGateway(url: paymentURL, context: result.context)
                } else {
                    self.showLottiePopup(title: result.response.message, type: .payOrder)
                }
            }
            .store(in: &cancellables)
        
        viewModel.reviewPublisher
            .compactMap { $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                self.showLottiePopup(title: result.message)
            }
            .store(in: &cancellables)
        
        viewModel.acceptInvoicePublisher
            .compactMap { $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                if let paymentURL = result.response.data?.checkoutURL {
                    self.showPaymentGateway(url: paymentURL, context: result.context)
                } else {
                    self.showLottiePopup(title: result.response.message)
                }
            }
            .store(in: &cancellables)
        
        viewModel.rejectInvoicePublisher
            .compactMap { $0 }
            .sinkOnMain{ [weak self] result in
                guard let self = self else { return }
                self.showLottiePopup(title: result.message)
            }
            .store(in: &cancellables)

        error(viewModel.errorPublisher)
    }
    
    
    func viewSetup(model : OrderDetailsModel){
        providerView.setupData(model: model)
        orderDetailsView.getDataSource(model: model, type: .orderDetails)
        let requestedServices = model.getRequestedServicesList()
        requestedServicesView.isHidden = requestedServices.isEmpty
        requestedServicesView.getDataSource(
            items: requestedServices,
            title: "requested_service".localized
        )
        
        problemDescView.getDataSource(problemDesc: model.description ?? "", imageList: model.getProblemDescImages(), type: .orderDetails)
        problemDescView.delegate = self
        
        geograpgicLocationView.setupData(location: model.address ?? "", lat: model.lat?.toDouble() ?? 0.0, long: model.long?.toDouble() ?? 0.0 , type :.orderDetails)
        
        orderSummryView.getDataSource(model: model,type : .orderSummary)
        cancellationView.setupData(context: model.closeReason , cosmosValue: nil, type: .cancelReason)
        feedbackView.setupData(context: model.review?.comment , cosmosValue: model.review?.rate, type: .feedback)
        
        if model.status == .scheduled {
            let noteKey = model.orderTimeEditLimitUnit == "minutes"
                ? "edit_service_time_note_minutes" : "edit_service_time_note"
            orderNotesLabel.text = String(format: noteKey.localized, model.orderTimeEditLimit ?? "")
        } else {
            orderNotesLabel.text = "provider_issued_invoice".localized
        }
    }
    
    func handleShowButtonsAndViews(model : OrderDetailsModel) {
        cancelOrderButton.isHidden = model.isCancelButtonHidden
        payNowButton.isHidden = model.isPayButtonHidden
        cancellationView.isHidden = model.isCancelViewHidden
        feedbackView.isHidden = model.isFeedbackViewHidden
        orderNotesView.isHidden = model.isOrderNotesHidden
        editCancelStackView.isHidden = model.isEditTimeCancelOrderStackHidden
        rateServicebutton.isHidden = model.isRateButtonHidden
        billButonsStackView.isHidden = model.isBillStackHidden
       // chatUIButton.isHidden = model.isChatButtonHidden
        reportUIButton.isHidden = model.isComplaintButtonHidden
        billUIButton.isHidden = model.isBillButtonHidden
        firstCancelStackView.isHidden = model.isCancelButtonHidden
    }

    func handleShowPledge(model : OrderDetailsModel) {
        guard model.status != .finished,
              model.status != .refused,
              model.status != .closed,
              model.pledgeSeen == false,
              !hasShownPledge,
              let pledge = model.pledge,
              !pledge.trimWhiteSpace().isEmpty else { return }
        hasShownPledge = true
        showPledgePopup(content: pledge)
    }

    func handleActions(type :OrderDetailsLottieTypes){
        switch type {
        case .cancelOrder:
            let tabBar  = AppTabBarController()
            tabBar.selectedIndex = 0
            AppHelper.changeWindowRoot(vc: tabBar)
        case .payOrder:
            viewModel.getOrderDetails()
        case .sendFeedback:
            break
        case .rejectInvoice:
            let tabBar  = AppTabBarController()
            tabBar.selectedIndex = 0
            AppHelper.changeWindowRoot(vc: tabBar)
        }
    }
    
    //MARK: - Action -
    
    @objc private func isOrderChanged() {
        viewModel.getOrderDetails()
    }
    
    @IBAction func didTapCancelOrder(_ sender: UIButton) {
        viewModel.getCancelOrderReasons()
    }
    
    @IBAction func didTapPayNow(_ sender: UIButton) {
        showPaymentAlertPopup(paymentTimeoutMessage: viewModel.orderDetailsModel?.paymentTimeoutMessage ?? "")
    }
    
    @IBAction func didTapEditTime(_ sender: UIButton) {
        goToEditServiceTime()
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        viewModel.getCancelOrderReasons()
    }
    
    @IBAction func didTapRateService(_ sender: UIButton) {
        showReviewPopup()
    }
    
    @IBAction func didTapAcceptInvoice(_ sender: UIButton) {
        viewModel.paymentNavType = .invoice
        viewModel.getPaymentMethods()
    }
    
    @IBAction func didTapRejectInvoice(_ sender: UIButton) {
        viewModel.orderReasonType = .rejectInvoice
        viewModel.getCancelOrderReasons()
    }
    
    @objc func didTapChatButton(){
        goToChat()
    }
    
    @objc func didTapReportButton(){
        goToComplaints()
    }
    
    @objc func didTapBillButton(){
        guard let url = viewModel.orderDetailsModel?.invoiceUrl else { return }
        showBillPopup(url: url)
    }
}

//MARK: - Routes -

extension OrderDetailsVC {
    
    func showOrderReasonSelectionPopup(list : [CancelReasonsModel]){
        let popup = OrderReasonSelectionView()
        popup.appear(sender: self)
        popup.delegate = self
        popup.getDataSource(reasonsList: list, type: viewModel.orderReasonType)
    }
    
    func showLottiePopup(title: String , type :OrderDetailsLottieTypes){
        let vc = LottiePopup()
        vc.appear(sender: self)
        vc.setupView(title: title, type: .normal)
        vc.onPopupHidden = {
            self.handleActions(type :type)
        }
    }
    
    func showPaymentAlertPopup(paymentTimeoutMessage: String){
        let popup = PaymentAlertPopup()
        popup.appear(sender: self)
        popup.setupView(paymentTimeoutMessage: paymentTimeoutMessage)
        popup.delegate = self
    }
    
    func showPaymentMethodPopup(paymentMethodsList : [PaymentMethodModel]){
        let popup = PaymentMethodPopup()
        popup.appear(sender: self)
        popup.getDataSource(paymentMethodsList: paymentMethodsList)
        popup.delegate = self
    }
    
    func goToEditServiceTime(){
        let vc = EditServiceTimeVC(viewModel: EditServiceTimeVM(orderId: viewModel.orderId))
        vc.delegate = self
        push(vc)
    }
    
    func goToChat(){
        let vc = ChatVC(viewModel: ChatVM(roomId:viewModel.orderDetailsModel?.roomId ?? 0))
        push(vc, animated: true)
    }
    
    func showBillPopup(url: String) {
        let vc = WebViewController()
        vc.urlString = url

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        present(nav, animated: true)
    }

    func showPaymentGateway(url: String, context: OrderPaymentContext) {
        let vc = PaymentWebViewController()
        vc.urlString = url
        vc.orderPayment = context
        vc.onPaymentAccepted = { [weak self] in
            self?.viewModel.getOrderDetails()
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
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

    func showPledgePopup(content: String){
        let popup = PledgePopup()
        popup.delegate = self
        popup.setupView(content: content)
        popup.appear(sender: self)
    }
}

//MARK: - Delegation -

extension OrderDetailsVC : OrderReasonSelectionProtocol ,PaymentAlertPopupProtocol,PaymentMethodPopupProtocol,EditServiceTimeProtocol,RatingPopupProtocol ,ProblemDescViewDelegate, PledgePopupProtocol{

    func didAgreeToPledge() {
        viewModel.acceptPledge()
    }

    
    func didSelectReson(reason: String, type: OrderReasonSelectionType) {
        switch type {
        case .cancelOrder:
            viewModel.cancelOrder(reason: reason)
        case .rejectInvoice:
            viewModel.rejectInvoice(reason: reason)
        }
    }
    
    func didTapConfirm() {
        viewModel.getPaymentMethods()
    }
    
    func didSelectPaymentMethod(paymentMethod: String) {
        switch viewModel.paymentNavType {
        case .order:
            viewModel.payOrderrequest(paymentType: paymentMethod)
        case .invoice:
            viewModel.acceptInvoice(paymentMethod: paymentMethod)
        }
    }
    
    func didEditTime() {
        viewModel.getOrderDetails()
    }
    
    func didTapConfirm(rate: Double, comment: String?) {
        viewModel.createReview(model: CustomerReviewModel(orderId: viewModel.orderId, secondUserId: viewModel.orderDetailsModel?.delegateId ?? 0, rate: rate, comment: comment))
    }
    
    func didSelectImage(_ image: ProblemDescImageType) {
        let vc = ImageViewerVC(viewModel: ImageViewerVM(image: image))
        vc.appear(sender: self)
    }
}
