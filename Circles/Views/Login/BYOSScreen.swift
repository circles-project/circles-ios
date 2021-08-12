//
//  BYOSScreen.swift
//  Circles
//
//  Created by Charles Wright on 8/9/21.
//

import SwiftUI
import StoreKit

extension SKProduct.PeriodUnit {
    var string: String {
        switch(self) {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }
}

struct BYOSProductCard: View {
    var product: SKProduct
    @Binding var selectedProduct: SKProduct?

    var body: some View {
        let selected: Bool = product == self.selectedProduct
        let borderColor = Color.accentColor
        let backgroundColor = selected ? Color.accentColor : Color.clear
        let textColor = self.selectedProduct == nil ? Color.primary : (selected ? Color.white : Color.gray)

        return Button(action: {self.selectedProduct = product}) {
            VStack {
                Text(product.localizedTitle)
                    .font(.headline)
                Text(product.localizedDescription)
                    .font(.subheadline)

                let period = product.subscriptionPeriod!
                let price = product.regularPrice!
                //Text("\(price) per \(period.numberOfUnits) \(period.unit.string)(s)")
                HStack {
                    Text(price)
                    Text("/")
                    if period.numberOfUnits > 1 {
                        Text("\(period.numberOfUnits) \(period.unit.string)s")
                    } else {
                        Text(period.unit.string)
                    }
                }
                .font(.headline)

            }
            .foregroundColor(textColor)
            .padding()
            .frame(width: 300, height: 100)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BYOSPurchaseView: View {
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    //@EnvironmentObject var appStore: AppStoreInterface
    @ObservedObject var appStore: AppStoreInterface
    @State var selectedProduct: SKProduct?
    @Environment(\.presentationMode) var presentation

    func sortProductsByPrice(p0: SKProduct, p1: SKProduct) -> Bool {
        let d0 = p0.price as Decimal
        let d1 = p1.price as Decimal
        return d0 < d1
    }

    var productsList: some View {
        VStack {
            let products = appStore.byosProducts.sorted(by: sortProductsByPrice)
            ForEach(products, id: \.self) { product in
                BYOSProductCard(product: product, selectedProduct: $selectedProduct)
            }
        }
    }


    var body: some View {
        VStack {
            Text("Bring-Your-Own-Server\nSubscription Options")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("Use of Circles with non-Kombucha accounts requires an active subscription.")
                Text("Your support helps to keep Circles private and ad-free forever.  We don't show ads.  We will never track you or sell your data.  We work for you.")
                    .font(.caption)
                    //.padding()

                //Spacer()

                //Text("")

                Text("Select a subscription option below to proceed:")
            }
            .padding()

            productsList

            Spacer()

            Text("Subscriptions will automatically renew until canceled")
                .font(.footnote)
            Button(action: {
                if let product = selectedProduct {
                    appStore.purchaseProduct(product: product) { response in
                        switch response {
                        case .failure(let err):
                            print("BYOS\tFAIL!  Couldn't purchase [\(product.productIdentifier) -- \(err)]")
                        case .success(let productId):
                            print("BYOS\tYay!  Purchase completed for \(product.productIdentifier) / \(productId)")
                            self.presentation.wrappedValue.dismiss()
                        }
                    }
                }
            }) {
                Text("Continue")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(selectedProduct == nil)

        }
        .padding()
    }
}

struct BYOSScreen: View {
    @ObservedObject var appStore: AppStoreInterface
    @Environment(\.presentationMode) var presentation



    var body: some View {
        VStack {
            if appStore.hasCurrentSubscription() {
                Text("Thank you for your support!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Spacer()

                Button(action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }

                Spacer()

            } else {
                BYOSPurchaseView(appStore: appStore)
            }
        }
    }
}

/*
struct BYOSScreen_Previews: PreviewProvider {
    static var previews: some View {
        BYOSScreen()
    }
}
*/
