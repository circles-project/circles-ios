//
//  SubscriptionForm.swift
//  Circles
//
//  Created by Charles Wright on 11/27/23.
//

import SwiftUI
import StoreKit

import Matrix

struct SubscriptionForm: View {
    var session: UIAuthSession
    @ObservedObject var appStore: AppStoreInterface
    
    // FIXME Hard-coding this for initial development - Get this from the UIA session params
    let productIds = [
        "org.futo.circles.individual_monthly",
        "org.futo.circles.family_monthly",
    ]
    @State var products: [Product] = []
    @State var selectedProduct: Product?
    @State var selectedTransaction: Transaction?

    var alreadyPurchased: Bool {
        guard let product = selectedProduct
        else {
            return false
        }
        
        return appStore.isPurchased(product)
    }
    
    var body: some View {
        VStack {
            Text("App Store Subscriptions")

            ScrollView {
                ForEach(products) { product in
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        AsyncButton(action: {
                            // Select the product
                            selectedProduct = product
                            // Do we already own the product?  Maybe we have family sharing, or we had previously started signing up and were interrupted
                            if let entitlement = await product.currentEntitlement {
                                selectedTransaction = try? appStore.checkVerified(entitlement)
                            }
                        }) {
                            Text(product.displayPrice)
                                .padding()
                        }
                    }
                }
            }
            
            Spacer()
            
            if let transaction = selectedTransaction {
                AsyncButton(action: {
                    
                    let signedTransaction = String(data: transaction.jsonRepresentation, encoding: .utf8)
                    
                    // Now do the apple storekit v2 UIA stage
                    
                    // Need the bundle id, the StoreKit environment, and a few other things...
                    let bundleId = transaction.appBundleID
                    let productId = transaction.productID
                    
                    // Send bundleId, productId, and signedTransaction to the server
                    
                    throw CirclesError("Not implemented")
                    
                }) {
                    Text("Continue")
                }
            }
            else {
                AsyncButton(action: {
                    guard let product = selectedProduct
                    else {
                        print("Error: Can't purchase a subscription when no product is selected")
                        return
                    }
                    
                    let transaction = try? await appStore.purchase(product)
                }) {
                    Text("Purchase")
                }
                .disabled(alreadyPurchased)
            }
            

        }
        .task {
            if let products = try? await Product.products(for: productIds) {
                print("Loaded \(products.count) products")
                await MainActor.run {
                    self.products = products
                }
            } else {
                print("Failed to get subscription products")
            }
        }
    }
}

