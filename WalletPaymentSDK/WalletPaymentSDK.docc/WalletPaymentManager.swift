

import Foundation

import UIKit

// Delegate protocol for payment outcomes
@objc public protocol WalletPaymentDelegate: AnyObject {
    func paymentDidSucceed()
    func paymentDidFail(withError: String)
    func paymentDidCancel()
}

@objc public class WalletPaymentManager: NSObject {
    // Public properties for configuration
    @objc public var username: String?
    @objc public var purchaseDetails: [String: String] = [:] // e.g., ["Item": "Shirt", "Price": "$29.99"]
    @objc public var totalAmount: Double = 0.0
    @objc public var walletBalance: Double = 0.0 // Wallet balance provided by the host app
    @objc public weak var delegate: WalletPaymentDelegate?
    
    private let presentingViewController: UIViewController
    private var charges: Double = 1.50 // Example fixed charge; could be configurable
    
    // Initialize with the presenting view controller
    @objc public init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }
    
    // Start the payment flow
    @objc public func startPaymentFlow() {
        checkUserLogin()
    }
    
    // Check if user is logged in
    private func checkUserLogin() {
        if username == nil || username?.isEmpty == true {
            showLoginPopup()
        } else {
            showPurchaseDetailsPopup()
        }
    }
    
    // Show login popup if username is missing
    private func showLoginPopup() {
        let alert = UIAlertController(title: "Login Required",
                                      message: "Please log in to proceed with payment.",
                                      preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { [weak self] _ in
            guard let username = alert.textFields?.first?.text, !username.isEmpty else {
                self?.showLoginPopup() // Re-show if empty
                return
            }
            self?.username = username
            self?.showPurchaseDetailsPopup()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.paymentDidCancel()
        }
        
        alert.addAction(loginAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    // Show purchase details popup
    private func showPurchaseDetailsPopup() {
        let popupVC = UIViewController()
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10
        popupVC.view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: popupVC.view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: popupVC.view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let detailsLabel = UILabel()
        var detailsText = "Purchase Details:\n"
        for (key, value) in purchaseDetails {
            detailsText += "\(key): \(value)\n"
        }
        detailsLabel.text = detailsText
        detailsLabel.numberOfLines = 0
        contentView.addSubview(detailsLabel)
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            detailsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissPopup(_:)), for: .touchUpInside)
        contentView.addSubview(cancelButton)
        
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Next", for: .normal)
        nextButton.addTarget(self, action: #selector(showAmountBreakdownPopup(_:)), for: .touchUpInside)
        contentView.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController.present(popupVC, animated: true, completion: nil)
        }
    }
    
    // Show amount and charges breakdown popup
    private func showAmountBreakdownPopup() {
        let popupVC = UIViewController()
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10
        popupVC.view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: popupVC.view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: popupVC.view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        let breakdownLabel = UILabel()
        breakdownLabel.text = "Amount: $\(String(format: "%.2f", totalAmount))\nCharges: $\(String(format: "%.2f", charges))\nTotal: $\(String(format: "%.2f", totalAmount + charges))"
        breakdownLabel.numberOfLines = 0
        contentView.addSubview(breakdownLabel)
        breakdownLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            breakdownLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            breakdownLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        
        let passcodeField = UITextField()
        passcodeField.placeholder = "Enter Passcode"
        passcodeField.isSecureTextEntry = true
        contentView.addSubview(passcodeField)
        passcodeField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passcodeField.topAnchor.constraint(equalTo: breakdownLabel.bottomAnchor, constant: 20),
            passcodeField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            passcodeField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissPopup(_:)), for: .touchUpInside)
        contentView.addSubview(cancelButton)
        
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.addTarget(self, action: #selector(processPayment(_:)), for: .touchUpInside)
        contentView.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        DispatchQueue.main.async { [weak self] in
            self?.presentingViewController.present(popupVC, animated: true, completion: nil)
        }
    }
    
    // Process the payment and show status
    @objc private func processPayment(_ sender: UIButton) {
        guard let passcodeField = (sender.superview?.subviews.compactMap { $0 as? UITextField }.first),
              let passcode = passcodeField.text, !passcode.isEmpty else {
            return // Could add a popup here for "Enter passcode"
        }
        
        presentingViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let popupVC = UIViewController()
            popupVC.modalPresentationStyle = .overFullScreen
            popupVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            let contentView = UIView()
            contentView.backgroundColor = .white
            contentView.layer.cornerRadius = 10
            popupVC.view.addSubview(contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.centerXAnchor.constraint(equalTo: popupVC.view.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: popupVC.view.centerYAnchor),
                contentView.widthAnchor.constraint(equalToConstant: 300),
                contentView.heightAnchor.constraint(equalToConstant: 150)
            ])
            
            let statusLabel = UILabel()
            statusLabel.text = "Processing Payment..."
            contentView.addSubview(statusLabel)
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
            
            DispatchQueue.main.async { [weak self] in
                self?.presentingViewController.present(popupVC, animated: true) {
                    // Simulate payment processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self else { return }
                        let totalDeduction = self.totalAmount + self.charges
                        if self.walletBalance >= totalDeduction {
                            statusLabel.text = "Payment Successful"
                            self.delegate?.paymentDidSucceed()
                        } else if Int.random(in: 0...1) == 0 { // Simulate random failure
                            statusLabel.text = "Payment Failed"
                            self.delegate?.paymentDidFail(withError: "Transaction error")
                        } else {
                            statusLabel.text = "Insufficient Funds to Complete the Transaction"
                            self.delegate?.paymentDidFail(withError: "Insufficient funds")
                        }
                    }
                }
            }
        }
    }
    
    // Helper to dismiss popups
    @objc private func dismissPopup(_ sender: UIButton) {
        presentingViewController.dismiss(animated: true) { [weak self] in
            self?.delegate?.paymentDidCancel()
        }
    }
    
    // Helper to transition to amount breakdown
    @objc private func showAmountBreakdownPopup(_ sender: UIButton) {
        presentingViewController.dismiss(animated: true) { [weak self] in
            self?.showAmountBreakdownPopup()
        }
    }
}
