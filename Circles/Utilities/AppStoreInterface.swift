//
//  AppStoreInterface.swift
//  Circles
//
//  Created by Charles Wright on 7/1/21.
//

import Foundation
import StoreKit

// See Apple docs at https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/setting_up_the_transaction_observer_for_the_payment_queue?changes=latest_minor
// and https://developer.apple.com/documentation/storekit/original_api_for_in-app_purchase/offering_completing_and_restoring_in-app_purchases?changes=latest_minor

class AppStoreInterface: NSObject, SKPaymentTransactionObserver, ObservableObject {

    @Published var products = [SKProduct]()

    //Initialize the store observer.
    override init() {
        super.init()
        //Other initialization here.
    }

    //Observe transaction updates.
    func paymentQueue(_ queue: SKPaymentQueue,updatedTransactions transactions: [SKPaymentTransaction]) {
        //Handle transaction states here.
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing: break
            // Do not block the UI. Allow the user to continue using the app.
            case .deferred: print("APPSTORE\tPurchase deferred")
            // The purchase was successful.
            case .purchased:
                print("APPSTORE\tPurchase was successful")
                // Remember that we purchased this
                UserDefaults.standard.set(true, forKey: transaction.payment.productIdentifier)
                // Finish the successful transaction.
                SKPaymentQueue.default().finishTransaction(transaction)
            // The transaction failed.
            case .failed:
                print("APPSTORE\tTransaction failed")
                SKPaymentQueue.default().finishTransaction(transaction)

            // There're restored products.
            case .restored:
                print("APPSTORE\tTransaction is a restore")
                SKPaymentQueue.default().finishTransaction(transaction)

            @unknown default: fatalError("APPSTORE\tUnknown fatal error")
            }
        }
    }

    func fetchProducts(matchingIdentifiers identifiers: [String]) {
        print("APPSTORE\tFetching products...")

        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)

        // Initialize the product request with the above identifiers.
        let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self

        // Send the request to the App Store.
        productRequest.start()
    }

    func purchaseProduct(product: SKProduct) {
        print("APPSTORE\tTrying to purchase product \(product.productIdentifier)")
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("APPSTORE\tError: User can't make payment.")
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
                    self.products.append(product)
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
