//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  AppStoreSignUpScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import StoreKit

struct MembershipProductCard: View {
    @EnvironmentObject var appStore: AppStoreInterface
    var product: SKProduct
    @Binding var selectedProduct: SKProduct?

    var body: some View {
        let alreadyPurchased = UserDefaults.standard.bool(forKey: product.productIdentifier) || appStore.purchased.contains(product.productIdentifier)
        let selected: Bool = product == self.selectedProduct
        //let borderColor = self.selectedProduct == nil ? Color.accentColor : (selected ? Color.primary : Color.accentColor)
        let textColor = self.selectedProduct == nil ? Color.primary : (selected ? Color.white : Color.gray)
        let brightColor = getColor(product)
        let backgroundColor = selected ? brightColor : Color.clear
        let borderColor = brightColor


        return Button(action: {
            self.selectedProduct = product
        }) {
            VStack(alignment: .leading) {
                let bigFont = Font.title2
                HStack {

                    Text("\(product.regularPrice!)")
                        .font(bigFont)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)

                    //Spacer()
                    Text(" for ")
                        .font(bigFont)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    Text(product.localizedTitle)
                        .font(bigFont)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)

                }

                /*
                Text(product.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(textColor)
                */
            }
            //.foregroundColor(textColor)
            .padding()
            .frame(width: 300, height: 50)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(alreadyPurchased)
    }
}

func getColor(_ maybeProduct: SKProduct?) -> Color {
    guard let product = maybeProduct else {
        return Color.gray
    }
    if product.productIdentifier.contains("premium") {
        return Color.pink
    } else {
        return Color.purple
    }
}

struct AppStoreSubscriptionForm: View {
    @EnvironmentObject var appStore: AppStoreInterface

    var matrix: MatrixInterface
    @Binding var uiaaState: UiaaSessionState?

    @State var selectedProduct: SKProduct?

    var buttonBar: some View {
        HStack {
            Button(action: {
                //self.selectedScreen = .signupMain
                uiaaState = nil
            }) {
                Text("Cancel")
                    .font(.footnote)
                    .padding(.top, 5)
                    .padding(.leading, 10)
            }
            Spacer()
            Button(action: {
                appStore.restoreProducts()
            }) {
                Text("Restore purchases")
                    .font(.footnote)
                    .padding(.top, 5)
                    .padding(.trailing, 10)
            }
        }
    }

    func sortProductsByPrice(p0: SKProduct, p1: SKProduct) -> Bool {
        let d0 = p0.price as Decimal
        let d1 = p1.price as Decimal
        return d0 < d1
    }

    var individualStandardPlans: some View {
        VStack {
            VStack(alignment: .leading) {
                Label("Individual plans - Standard", systemImage: "person.circle")
                    .font(.headline)
                    //.fontWeight(.bold)
                Text("Our standard individual account gives you up to 5 primary social circles with up to 150 contacts each, unlimited private groups, and up to 5 GB of secure cloud storage.  Plus unlimited small circles of fewer than 20 people.")
                    .font(.footnote)
                    .padding()
            }

            let individualProducts = appStore.membershipProducts
                .filter {
                    $0.isFamilyShareable == false
                }
                .filter {
                    $0.productIdentifier.contains("standard")
                }
                .sorted(by: sortProductsByPrice)

            ForEach(individualProducts, id: \.self) { product in
                MembershipProductCard(product: product, selectedProduct: $selectedProduct)
            }
        }
    }

    var individualPremiumPlans: some View {
        VStack {

            let products = appStore.membershipProducts
                .filter {
                    $0.isFamilyShareable == false
                }
                .filter {
                    $0.productIdentifier.contains("premium")
                }
                .sorted(by: sortProductsByPrice)

            VStack(alignment: .leading) {
                Label("Individual plans - Premium", systemImage: "person.circle")
                    .font(.headline)
                    //.fontWeight(.bold)
                Text("Our premium individual account gives you 10 circles with up to 250 contacts each, unlimited private groups, and 10 GB of secure cloud storage.  Plus an unlimited number of small circles with up to 20 people.")
                    .font(.footnote)
                    .padding()
            }

            ForEach(products, id: \.self) { product in
                MembershipProductCard(product: product, selectedProduct: $selectedProduct)
            }
        }
    }

    var purchaseForm: some View {
        VStack {
            Text("Select subscription")
                .font(.title2)
                .fontWeight(.bold)
                .padding()

            ScrollView {

                individualStandardPlans

                individualPremiumPlans

            }

            Spacer()

            Text("Subscriptions will automatically renew until canceled")
                .font(.footnote)
            let buttonColor = getColor(selectedProduct)
            Button(action: {
                if let product = selectedProduct {
                    appStore.purchaseProduct(product: product) { response in
                        // FIXME -- Handle the callback here...
                    }
                }
            }) {
                Text("Subscribe for \(selectedProduct?.localizedTitle ?? "")")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(buttonColor)
                    .cornerRadius(10)
            }
            .disabled(selectedProduct == nil || appStore.purchased.contains(selectedProduct!.productIdentifier))
            .padding()
        }
    }

    var body: some View {
        VStack {
            buttonBar

            if let purchasedProductId = appStore.purchased.first(where: { productId in
                !productId.contains("byos")
            })
            {
                Spacer()

                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("Subscription success!")
                }
                Text("Thank you!")

                Spacer()

                Button(action: {
                    // Send the receipt
                    print("SIGNUP-APPSTORE\tAuthenticating with purchased product \(purchasedProductId)")
                }) {

                    Text("Next: Create your account")
                }
                .padding()
                .frame(width: 300.0, height: 40.0)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(10)

                Spacer()

            } else {
                purchaseForm
            }

        }
        .padding()
    }
}

/*
struct AppStoreSignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreSignUpScreen()
    }
}
*/
