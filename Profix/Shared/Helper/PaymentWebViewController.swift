//
//  PaymentWebViewController.swift
// NewBase
//
//  Created by Mohamed Hadwa on 10/07/2025.
//
import UIKit
import WebKit

class PaymentWebViewController: UIViewController, WKNavigationDelegate, UIAdaptivePresentationControllerDelegate {
    var urlString: String?
    var orderPayment: OrderPaymentContext?
    var onPaymentAccepted: (() -> Void)?

    private var webView: WKWebView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var paymentCompletion = PaymentCompletionHandler(
        checkoutURL: urlString,
        orderPayment: orderPayment
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Payment".localized
        view.backgroundColor = .white
        setupWebView()
        setupLoadingIndicator()
        navigationController?.presentationController?.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(cancelTapped)
        )

        guard let urlString, let url = URL(string: urlString) else {
            dismiss(animated: true)
            return
        }
        webView.load(URLRequest(url: url))
    }

    private func setupWebView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupLoadingIndicator() {
        loadingIndicator.color = .main
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        loadingIndicator.startAnimating()
    }

    @objc private func cancelTapped() {
        paymentCompletion.cancel()
        dismiss(animated: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        paymentCompletion.cancel()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        loadingIndicator.stopAnimating()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        loadingIndicator.stopAnimating()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard !paymentCompletion.isComplete else {
            decisionHandler(.cancel)
            return
        }

        guard navigationAction.targetFrame?.isMainFrame == true,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        guard let outcome = paymentCompletion.handleRedirect(url) else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        let paymentAccepted = outcome == .success ? onPaymentAccepted : nil
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true) {
                paymentAccepted?()
            }
        }
    }
}


class WebViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    var urlString: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupWebView()
        setupNavigationBar()
        loadURL()
    }

    private func setupWebView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "invoice".localized

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareTapped)
            )
        ]
    }

    private func loadURL() {
        guard let urlString,
              let url = URL(string: urlString) else { return }

        webView.load(URLRequest(url: url))
    }

    // MARK: - Share / Download

    @objc private func shareTapped() {
        generatePDFfromWebView()
    }
    
    private func generatePDFfromWebView() {
        let config = WKPDFConfiguration()
        
        webView.createPDF(configuration: config) { [weak self] result in
            switch result {
            case .success(let data):
                let fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("invoice.pdf")

                do {
                    try data.write(to: fileURL)
                    self?.showShareSheet(fileURL: fileURL)
                } catch {
                    print("PDF save error:", error)
                }

            case .failure(let error):
                print("PDF generation error:", error)
            }
        }
    }
    
    private func showShareSheet(fileURL: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        present(activityVC, animated: true)
    }
}
