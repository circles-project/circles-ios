//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  AppStoreSignUpScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import StoreKit

#if false

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
                let bigFont = Font.headline
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
            .frame(width: 300, height: 40)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            //.padding()
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
        return Color.orange
    } else {
        return Color.purple
    }
}

struct AppStoreSubscriptionForm: View {
    @EnvironmentObject var appStore: AppStoreInterface

    var matrix: MatrixInterface
    @Binding var uiaaState: UIAA.SessionState?
    @Binding var authFlow: UIAA.Flow?

    @State var selectedProduct: SKProduct?

    let stage = LOGIN_STAGE_APPLE_SUBSCRIPTION

    var buttonBar: some View {
        HStack {
            Button(action: {
                //self.selectedScreen = .signupMain
                uiaaState = nil
            }) {
                Text("Cancel")
                    .font(.footnote)
                    //.padding(.top, 5)
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

            let products = appStore.membershipProducts
                .filter {
                    $0.isFamilyShareable == false
                }
                .filter {
                    $0.productIdentifier.contains("standard")
                }
                .sorted(by: sortProductsByPrice)

            if !products.isEmpty {

                VStack(alignment: .leading) {
                    Label("Individual plans - Standard", systemImage: "person.circle")
                        .font(.headline)
                        //.fontWeight(.bold)

                    Image("120896110_s")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Our standard individual account gives you up to 5 primary social circles with up to 150 contacts each, unlimited private groups, and up to 5 GB of secure cloud storage.  Plus, you can have an unlimited number of small circles of fewer than 20 people.")
                        .font(.footnote)


                }
                .padding()

                ForEach(products, id: \.self) { product in
                    MembershipProductCard(product: product, selectedProduct: $selectedProduct)
                }
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

            if !products.isEmpty {
                VStack(alignment: .leading) {
                    Label("Individual plans - Premium", systemImage: "person.circle")
                        .font(.headline)
                        //.fontWeight(.bold)

                    Image("124972425_s")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Our premium individual account lets you create 10 circles with up to 250 contacts each and unlimited private groups. Plus, you get 10 GB of secure cloud storage and an unlimited number of small circles with up to 20 people in each.")
                        .font(.footnote)
                }
                .padding()

                ForEach(products, id: \.self) { product in
                    MembershipProductCard(product: product, selectedProduct: $selectedProduct)
                }
            }
        }
    }

    var purchaseForm: some View {
        VStack(alignment: .center, spacing: 5) {

            ScrollView {

                Text("Circles Subscription Plans")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                let imageName = ["51616373_s", "134199050_s", "77851467_s"].randomElement()!
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()

                individualStandardPlans

                individualPremiumPlans

                Spacer()

            }


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
                let buttonText = selectedProduct == nil ? "Select an option to subscribe" : "Subscribe for \(selectedProduct?.localizedTitle ?? "")"
                Text(buttonText)
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(buttonColor)
                    .cornerRadius(10)
            }
            .disabled(selectedProduct == nil || appStore.purchased.contains(selectedProduct!.productIdentifier))
            //.padding()
        }
    }

    var body: some View {
        VStack {
            buttonBar

            if let receipt = AppStoreInterface.getReceipt()
            {
                Spacer()


                Text("Subscription success!")
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80.0, height: 80.0, alignment: .center)
                    .foregroundColor(.green)
                Text("Thank you!")

                Spacer()

                Button(action: {
                    // Send the receipt
                    print("SIGNUP-APPSTORE\tAuthenticating with purchase receipt \(receipt.prefix(20))...")
                    matrix.signupDoAppStoreStage(receipt: receipt) { response in
                        print("SIGNUP-APPSTORE\tGot response from homeserver")
                        if response.isSuccess {
                            print("SIGNUP-APPSTORE\tSuccess!  Moving on to the next UIAA stage...")
                            authFlow?.pop(stage: self.stage)
                        } else {
                            print("SIGNUP-APPSTORE\tRequest failed.")
                        }
                    }
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
        .padding(5)
    }
}
#endif

/*
struct AppStoreSignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreSignUpScreen()
    }
}
*/
