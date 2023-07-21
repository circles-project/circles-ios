//
//  AppStoreInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/1/21.
//

import Foundation
import StoreKit

import TPInAppReceipt
import Matrix

// See Apple docs at https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/setting_up_the_transaction_observer_for_the_payment_queue?changes=latest_minor
// and https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/offering_completing_and_restoring_in-app_purchases?changes=latest_minor
// and WWDC'17 video "Advanced StoreKit"
// and WWDC'18 video "Engineering StoreKit" https://developer.apple.com/videos/play/wwdc2018/705/

class AppStoreInterface: NSObject, SKPaymentTransactionObserver, ObservableObject {

    @Published var membershipProducts = [SKProduct]()

    @Published var purchased = [String]()

    @Published var transactionState: SKPaymentTransactionState?


    typealias PurchaseCallback = (String?) -> Void
    var callbacks: [String:PurchaseCallback] = [:]

    //Initialize the store observer.
    override init() {
        super.init()
        //Other initialization here.
    }

    // https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/validating_receipts_with_the_app_store
    static func getReceipt() -> String? {
        // Get the receipt if it's available
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path),
              let receiptData = try? Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        else {
            print("APPSTORE\tCouldn't get receipt")
            return nil
        }

        print(receiptData)

        let receiptString = receiptData.base64EncodedString(options: [])
        return receiptString
    }

    // https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device
    static func validateReceiptOnDevice(for productId: String) -> Bool {
        /// Initialize receipt
        guard let receipt = try? InAppReceipt.localReceipt() else {
            print("VALIDATE\tCouldn't get local receipt")
            return false
        }

        /// Base64 Encoded Receipt
        let base64Receipt = receipt.base64

        /// Check whether receipt contains any purchases
        let hasPurchases = receipt.hasPurchases

        /// All auto renewable `InAppPurchase`s,
        let purchases: [InAppPurchase] = receipt.autoRenewablePurchases

        /// all ACTIVE auto renewable `InAppPurchase`s,
        let activePurchases: [InAppPurchase] = receipt.activeAutoRenewableSubscriptionPurchases
        for purchase in activePurchases {

            // Is this the product that we're trying to validate?
            if purchase.productIdentifier == productId {
                print("Found active subscription for [\(productId)]")
                if let expiry = purchase.subscriptionExpirationDate {
                    print("\tExpires on \(expiry) -- Right now it's \(Date())")
                }
                return true
            }
        }

        // We didn't find a receipt for the product in question
        return false
    }

    //Observe transaction updates.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        //Handle transaction states here.
        for transaction in transactions {
            switch transaction.transactionState {

            case .purchasing:
                self.transactionState = .purchasing
                break

            // Do not block the UI. Allow the user to continue using the app.
            case .deferred:
                self.transactionState = .failed
                print("APPSTORE\tPurchase deferred")

            // The purchase was successful.
            case .purchased:
                print("APPSTORE\tPurchase was successful")

                // Need to validate the receipt
                // * For the 0.99 subscription to use your own server,
                //   we validate the receipt on the device
                let valid = AppStoreInterface.validateReceiptOnDevice(for: transaction.payment.productIdentifier)
                // * For subscriptions to our own server, we do the
                //   server validation approach

                let productId = transaction.payment.productIdentifier

                if valid {
                    // Remember that we purchased this
                    if let date = transaction.transactionDate {
                        UserDefaults.standard.set(date, forKey: productId)
                    }
                    self.purchased.append(productId)

                    if let callback = callbacks[productId] {
                        callback(productId)
                        callbacks[productId] = nil
                    }
                } else {
                    let msg = "Failed to validate purchase for [\(productId)]"
                    print("APPSTORE\t\(msg)")
                    
                    if let callback = callbacks[productId] {
                        let err = CirclesError(msg)
                        callback(nil)
                        callbacks[productId] = nil
                    }
                }
                // Finish the successful transaction.
                SKPaymentQueue.default().finishTransaction(transaction)

                self.transactionState = .purchased

            // The transaction failed.
            case .failed:
                let productId = transaction.payment.productIdentifier

                let msg = "Transaction failed"
                print("APPSTORE\t\(msg)")
                let err = CirclesError(msg)
                if let callback = callbacks[productId] {
                    callback(nil)
                    callbacks[productId] = nil
                }
                SKPaymentQueue.default().finishTransaction(transaction)

                self.transactionState = .failed

            // There're restored products.
            case .restored:
                print("APPSTORE\tTransaction is a restore")
                // Remember that we purchased this
                if let date = transaction.transactionDate {
                    UserDefaults.standard.set(date, forKey: transaction.payment.productIdentifier)
                }
                self.purchased.append(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
                self.transactionState = .restored

            @unknown default: fatalError("APPSTORE\tUnknown fatal error")
            }
        }
    }

    func fetchProducts(matchingIdentifiers identifiers: [String]) {
        print("APPSTORE\tFetching products...")
        for productId in identifiers {
            print("APPSTORE\t\tFetching matches for [\(productId)]")
        }

        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)

        // Initialize the product request with the above identifiers.
        let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self

        // Send the request to the App Store.
        productRequest.start()
    }

    func purchaseProduct(product: SKProduct, completion: @escaping (String?)->Void) {
        print("APPSTORE\tTrying to purchase product \(product.productIdentifier)")
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            callbacks[product.productIdentifier] = completion
            SKPaymentQueue.default().add(payment)
            //completion(.success(product.productIdentifier))
        } else {
            let msg = "User can't make payment."
            print("APPSTORE\tError: \(msg)")
            let err = CirclesError(msg)
            completion(nil)
        }
    }

    func restoreProducts() {
        print("APPSTORE\tRestoring purchased products")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func hasCurrentSubscription() -> Bool {
        /// Initialize receipt
        guard let receipt = try? InAppReceipt.localReceipt() else {
            print("VALIDATE\tCouldn't get local receipt")
            return false
        }

        /// all ACTIVE auto renewable `InAppPurchase`s,
        let activePurchases: [InAppPurchase] = receipt.activeAutoRenewableSubscriptionPurchases
        for purchase in activePurchases {

            // Is this the product that we're trying to validate?
            let productId = purchase.productIdentifier
            let matchingMembershipProducts = membershipProducts.filter { $0.productIdentifier == productId}

            if !matchingMembershipProducts.isEmpty {
                print("Found active subscription for [\(productId)]")
                if let expiry = purchase.subscriptionExpirationDate {
                    print("\tExpires on \(expiry) -- Right now it's \(Date())")
                }
                return true
            }
        }

        // We didn't find a receipt for the product in question
        return false
    }

    // This is where we'll be notified when the storefront changes
    // This is great because sometimes at startup, the storefront is nil
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        print("APPSTORE\tStorefront changed")
        if let countryCode = queue.storefront?.countryCode {
            print("APPSTORE\tNew storefront country code is [\(countryCode)]")
        } else {
            print("APPSTORE\tNew storefront is nil :(")
        }
    }

}

extension AppStoreInterface: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("APPSTORE\tHandling products request")

        if !response.products.isEmpty {
            for product in response.products {
                DispatchQueue.main.async {
                    print("APPSTORE\tFound product: \(product.productIdentifier)")
                    self.membershipProducts.append(product)
                }
            }
        }

        for identifier in response.invalidProductIdentifiers {
            print("APPSTORE\tIdentifier is invalid: \(identifier)")
        }

    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("APPSTORE\tRequest failed: \(error)")
    }

}

extension SKProduct {
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}
