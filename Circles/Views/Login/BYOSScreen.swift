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
            return "Day"
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
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
                /*
                Text(product.localizedTitle)
                    .font(.headline)
                Text(product.localizedDescription)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .font(.subheadline)
                */

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
                .padding()

            }
            .foregroundColor(textColor)
            .padding()
            .frame(width: 200, height: 40)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            //.padding()
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
            Text("Bring Your Own Server (BYOS)")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                //.padding()

            ScrollView {

            let imageName = ["124653629_s", "43324790_s"].randomElement()!
            Image(imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 5) {
                /*
                Text("So, you want to use Circles with your own server? Awesome!")
                    .font(.headline)
                    .lineLimit(3)
                */
                Text("Circles gives you the flexibility to use your own server, or a friend's, or a server from some other provider.  Either way, you can still keep in touch with other Circles users, because the servers can all talk to each other using an open, extensible protocol.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Use of Circles with third party accounts requires an active subscription.")
                    .font(.headline)
                    //.lineLimit(3)
                    //.minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)


                Text("Your support helps to keep Circles private and ad-free forever.  We don't show ads.  We will never track you or sell your data.  We work for you.")
                    .font(.caption)
                    //.lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)

                    //.padding()

                //Spacer()

                //Text("")

                Text("Select a subscription option below to proceed:")
                    .font(.headline)
                    //.minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)

            }
            .padding()

            productsList

            Spacer()
            }

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

            /*
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.red)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red))

            }
            */
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
