//
//  SubscriptionForm.swift
//  Circles
//
//  Created by Charles Wright on 11/27/23.
//

import SwiftUI
import StoreKit

import Matrix

struct SubscriptionUiaProductView: View {
    @ObservedObject var store: AppStoreInterface
    var product: Product
    @Binding var selectedProduct: Product?
    
    @State var purchased = false
    @State var errorTitle = ""
    @State var isShowingError: Bool = false
    
    var unit: String? {
        guard let subscription = product.subscription
        else { return nil }
        
        let plural = 1 < subscription.subscriptionPeriod.value
        
        let u: String
        switch subscription.subscriptionPeriod.unit {
        case .day:
            u = plural ? "\(subscription.subscriptionPeriod.value) days" : "day"
        case .week:
            u = plural ? "\(subscription.subscriptionPeriod.value) weeks" : "week"
        case .month:
            u = plural ? "\(subscription.subscriptionPeriod.value) months" : "month"
        case .year:
            u = plural ? "\(subscription.subscriptionPeriod.value) years" : "year"
        @unknown default:
            u = "period"
        }
        return u
    }
    
    func buy() async {
        do {
            if try await store.purchase(product) != nil {
                withAnimation {
                    selectedProduct = product
                }
            }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed purchase for \(product.id): \(error)")
        }
    }
    
    @ViewBuilder
    var subscribeButton: some View {
        VStack {
            if let unit = self.unit {
                Text(product.displayPrice)
                    .foregroundColor(.white)
                    .bold()
                    .padding(EdgeInsets(top: -4.0, leading: 0.0, bottom: -8.0, trailing: 0.0))
                Divider()
                    .background(Color.white)
                Text(unit)
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .padding(EdgeInsets(top: -8.0, leading: 0.0, bottom: -4.0, trailing: 0.0))
            } else {
                Text(product.displayPrice)
                    .foregroundColor(.white)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: 95)
        .foregroundColor(.white)
        .background(Color.accentColor)
        .cornerRadius(15)
    }
    
    @ViewBuilder
    var checkBox: some View {
        Text(Image(systemName: SystemImages.checkmark.rawValue))
            .bold()
            .padding()
            .frame(maxWidth: 95)
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(15)
    }
    
    var body: some View {
        let selected = selectedProduct == product
        let color: Color = selected ? .accentColor : .gray
        
        return HStack {
            let emoji = store.emoji(for: product.id)

            Text(emoji)
                .font(.system(size: 50))
                .frame(width: 50, height: 50)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .bold()
                Text(product.description)
                    .font(.subheadline)
            }
            
            Spacer()
            
            if purchased {
                checkBox
            } else {
                subscribeButton
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: 2)
        )
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .default(Text("Okay")))
        })
        .task {
            
            if let entitlement = await product.currentEntitlement,
               let transaction = try? store.checkVerified(entitlement) {
                await MainActor.run {
                    purchased = true
                }
            }
        }

    }
}

struct SubscriptionUIaForm: View {
    var session: UIAuthSession
    @EnvironmentObject var appStore: AppStoreInterface
    
    @State var productIds: [String] = []
    @State var products: [Product] = []
    @State var selectedProduct: Product?
    @State var selectedTransaction: Transaction?
    @State var jwsSignedTransaction: String?

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
                    AsyncButton(action: {
                        selectedProduct = product
                        
                        if let entitlement = await product.currentEntitlement,
                           let transaction = try? appStore.checkVerified(entitlement)
                        {
                            await MainActor.run {
                                selectedTransaction = transaction
                                jwsSignedTransaction = entitlement.jwsRepresentation
                            }
                        }
                    }) {
                        SubscriptionUiaProductView(store: appStore, product: product, selectedProduct: $selectedProduct)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            AsyncButton(action: {
                
                guard let product = selectedProduct
                else {
                    print("Error: Can't purchase a subscription when no product is selected")
                    return
                }
                
                if selectedTransaction == nil {
                    if let newTransaction = try? await appStore.purchase(product),
                       let entitlement = await product.currentEntitlement
                    {
                        await MainActor.run {
                            selectedTransaction = newTransaction
                            jwsSignedTransaction = entitlement.jwsRepresentation
                        }
                    }
                }
                
                if let transaction = selectedTransaction,
                   let jws = jwsSignedTransaction
                {
                    print("Transaction = \(transaction)")
                    //print("JWS = \(jws)")
                    
                    let toks = jws.split(separator: ".")
                    guard toks.count == 3,
                          let payloadData = Matrix.Base64.data(String(toks[1])),
                          let payload = String(data: payloadData, encoding: .utf8)
                    else {
                        print("Invalid JWS")
                        return
                    }
                    print("Got payload = \(payload)")
                    
                    // Now do the apple storekit v2 UIA stage
                    // Send bundleId, productId, and signedTransaction to the server
                    try await session.doAppStoreSubscriptionStage(bundleId: transaction.appBundleID,
                                                                  productId: transaction.productID,
                                                                  signedTransaction: jws)
                }
            }) {
                if selectedTransaction != nil,
                   jwsSignedTransaction != nil
                {
                    Text("Continue")
                }
                else if selectedProduct != nil {
                    Text("Purchase and Continue")
                }
                else {
                    Text("Select a Subscription Plan")
                }
            }
            .disabled(selectedProduct == nil)
            
            /*
            
            if let transaction = selectedTransaction,
               let jws = jwsSignedTransaction
            {
                AsyncButton(action: {
                              
                    print("Transaction = \(transaction)")
                    //print("JWS = \(jws)")
                    
                    let toks = jws.split(separator: ".")
                    guard toks.count == 3,
                          let payloadData = Matrix.Base64.data(String(toks[1])),
                          let payload = String(data: payloadData, encoding: .utf8)
                    else {
                        print("Invalid JWS")
                        return
                    }
                    print("Got payload = \(payload)")
                    
                    // Now do the apple storekit v2 UIA stage
                    // Send bundleId, productId, and signedTransaction to the server
                    try await session.doAppStoreSubscriptionStage(bundleId: transaction.appBundleID,
                                                                  productId: transaction.productID,
                                                                  signedTransaction: jws)
                    
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
                .disabled(alreadyPurchased || selectedProduct == nil)
            }
            */

        }
        .task {
            
            guard let productIds = session.getAppStoreProductIds()
            else {
                print("Failed to get App Store product id's")
                return
            }
            print("Found \(productIds.count) product id's")
            
            if let products = try? await Product.products(for: productIds)
            {
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

