//
//  AppStore.swift
//  Circles
//
//  Created by Charles Wright on 11/28/23.
//  Based on Apple's SKDemo project
//

/*
 Based on Store.swift from Apple's SKDemo project https://developer.apple.com/videos/play/wwdc2021/10114/
 https://developer.apple.com/documentation/storekit/in-app_purchase/implementing_a_store_in_your_app_using_the_storekit_api
 
 Copyright © 2023 Apple Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


/*
Abstract:
The store class is responsible for requesting products from the App Store and starting purchases.
*/

import Foundation
import StoreKit
import os

typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreError: Error {
    case failedVerification
}

//Define our app's subscription tiers by level of service, in ascending order.
public enum SubscriptionTier: Int, Comparable {
    case none = 0
    case standard = 1
    case premium = 2
    case pro = 3

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class AppStoreInterface: ObservableObject {

    @Published private(set) var nonConsumables: [Product]
    @Published private(set) var consumables: [Product]
    @Published private(set) var subscriptions: [Product]
    @Published private(set) var nonRenewables: [Product]
    
    @Published private(set) var purchasedProducts: [Product] = []
    @Published private(set) var purchasedNonRenewableSubscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [String: String] = [:]
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    var logger: os.Logger

    init() {
        
        logger = .init(subsystem: "AppStore", category: "AppStore")

        //Initialize empty products, and then do a product request asynchronously to fill them in.
        nonConsumables = []
        consumables = []
        subscriptions = []
        nonRenewables = []

        //Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions()

        Task {
            //During store initialization, request products from the App Store.
            //await requestProducts()

            //Deliver products that the customer purchases.
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func listenForTransactions() -> Task<Void, Error> {
        logger.debug("Listening for transactions")
        return Task.detached {
            self.logger.debug("Transaction listener task is running")
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                self.logger.debug("Got a transaction update")
                do {
                    let transaction = try self.checkVerified(result)
                    self.logger.debug("Transaction is verified")

                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    self.logger.error("Transaction failed verification")
                }
            }
        }
    }

    @MainActor
    func requestProducts(for identifiers: [String]) async throws -> [Product] {
        //Request products from the App Store using the identifiers that the caller provides.
        let storeProducts = try await Product.products(for: identifiers)

        var newNonConsumables: [Product] = []
        var newSubscriptions: [Product] = []
        var newNonRenewables: [Product] = []
        var newConsumables: [Product] = []

        //Filter the products into categories based on their type.
        for product in storeProducts {
            switch product.type {
            case .consumable:
                newConsumables.append(product)
            case .nonConsumable:
                newNonConsumables.append(product)
            case .autoRenewable:
                newSubscriptions.append(product)
            case .nonRenewable:
                newNonRenewables.append(product)
            default:
                //Ignore this product.
                self.logger.debug("Unknown product \(product.id)")
            }
        }

        //Sort each product category by price, lowest to highest, to update the store.
        nonConsumables = sortByPrice(newNonConsumables)
        subscriptions = sortByPrice(newSubscriptions)
        nonRenewables = sortByPrice(newNonRenewables)
        consumables = sortByPrice(newConsumables)

        return storeProducts
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        logger.debug("Purchasing product \(product.id)")
        
        //Begin purchasing the `Product` the user selects.
        guard let result = try? await product.purchase()
        else {
            logger.error("Purchase failed for \(product.id)")
            throw CirclesError("Purchase failed")
        }
        logger.debug("Purchase success for \(product.id)")
        

        switch result {
        case .success(let verification):
            
            let jws = verification.jwsRepresentation
            logger.debug("Got JWS representation: \(jws)")
            
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            //Always finish a transaction.
            await transaction.finish()

            await MainActor.run {
                self.objectWillChange.send()
            }
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) -> Bool {
        //Determine whether the user purchases a given product.
        switch product.type {
        case .nonRenewable:
            return purchasedNonRenewableSubscriptions.contains(product)
        case .nonConsumable:
            return purchasedProducts.contains(product)
        case .autoRenewable:
            guard let groupId = product.subscription?.subscriptionGroupID
            else {
                logger.error("Invalid subscription product \(product.id) -- No subscription info")
                //throw CirclesError("Invalid subscription product")
                return false
            }
            return purchasedSubscriptions[groupId] == product.id
        default:
            return false
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        logger.debug("Checking verification")
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedNonConsumables: [Product] = []
        var purchasedSubscriptions: [String: String] = [:]
        var purchasedNonRenewableSubscriptions: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)

                //Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .nonConsumable:
                    if let nonCon = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(nonCon)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }),
                       transaction.productID == "nonRenewing.standard" {
                        //Non-renewing subscriptions have no inherent expiration date, so they're always
                        //contained in `Transaction.currentEntitlements` after the user purchases them.
                        //This app defines this non-renewing subscription's expiration date to be one year after purchase.
                        //If the current date is within one year of the `purchaseDate`, the user is still entitled to this
                        //product.
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                   to: transaction.purchaseDate)!

                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                        }
                    }
                case .autoRenewable:
                    guard let status = await transaction.subscriptionStatus
                    else {
                        print("Found auto-renewable transaction \(transaction.id) for product \(transaction.productID) but it has no subscription status")
                        continue
                    }
                    guard status.state == .subscribed || status.state == .inGracePeriod
                    else {
                        print("Found auto-renewable transaction \(transaction.id) for product \(transaction.productID) but it's in state \(status.state.localizedDescription)")
                        continue
                    }
                    guard !transaction.isUpgraded
                    else {
                        print("Found auto-renewable transaction \(transaction.id) for product \(transaction.productID) but it's been upgraded")
                        continue
                    }
                    if let groupId = transaction.subscriptionGroupID {
                        print("Auto-renewable transaction \(transaction.id) has group id \(groupId) -- Setting active product to \(transaction.productID)")
                        purchasedSubscriptions[groupId] = transaction.productID
                        if let json = String(data: transaction.jsonRepresentation, encoding: .utf8) {
                            print("This transaction is: \(json)")
                        } else {
                            print("Failed to get JSON representation")
                        }
                    } else {
                        print("Found auto-renewable transaction \(transaction.id) for product \(transaction.productID) but it has no group id")
                    }
                    let otid = transaction.originalID
                default:
                    break
                }
            } catch {
                print()
            }
        }

        //Update the store information with the purchased products.
        self.purchasedProducts = purchasedNonConsumables
        self.purchasedNonRenewableSubscriptions = purchasedNonRenewableSubscriptions

        //Update the store information with auto-renewable subscription products.
        self.purchasedSubscriptions = purchasedSubscriptions

        //Check the `subscriptionGroupStatus` to learn the auto-renewable subscription state to determine whether the customer
        //is new (never subscribed), active, or inactive (expired subscription). This app has only one subscription
        //group, so products in the subscriptions array all belong to the same group. The statuses that
        //`product.subscription.status` returns apply to the entire subscription group.
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
    }

    func emoji(for productId: String) -> String {
        if productId.contains("family") {
            return "👥"
        } else {
            return "👤"
        }
    }

    func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }

    //Get a subscription's level of service using the product ID.
    func tier(for productId: String) -> SubscriptionTier {
        switch productId {
        case "subscription.standard":
            return .standard
        case "subscription.premium":
            return .premium
        case "subscription.pro":
            return .pro
        default:
            return .none
        }
    }
}
