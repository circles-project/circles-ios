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
    //var session: UIAuthSession
    
    // FIXME Hard-coding this for initial development - Get this from the UIA session params
    let productIds = [
        "org.futo.circles.individual_monthly",
        "org.futo.circles.family_monthly",
    ]
    @State var products: [Product] = []

    var body: some View {
        VStack {
            Text("App Store Subscriptions")
            ForEach(products) { product in
                HStack {
                    Text(product.displayName)
                    Spacer()
                    Button(action: {}) {
                        Text(product.displayPrice)
                            .padding()
                    }
                }
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

#Preview {
    SubscriptionForm()
}
