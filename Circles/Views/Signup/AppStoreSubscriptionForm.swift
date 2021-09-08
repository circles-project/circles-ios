//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  AppStoreSignUpScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import StoreKit

struct SubscriptionCard: View {
    let plan: String
    @Binding var selectedPlan: String

    static let colors = ["Basic": Color.pink, "Standard": Color.green, "Premium": Color.purple]

    var background: some View {
        if plan == selectedPlan {
            return AnyView(backgroundColor
                            .cornerRadius(10))
        } else {
            return AnyView(RoundedRectangle(cornerRadius: 10)
                            .stroke(backgroundColor, lineWidth: 2))
        }
    }

    var backgroundColor: Color {
        SubscriptionCard.colors[plan] ?? Color.accentColor
    }

    var textColor: Color {
        if plan == selectedPlan {
            return Color.white
        } else {
            return Color.primary
        }
    }

    var body: some View {
        Button(action: {
            self.selectedPlan = plan
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(plan)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Plan details, blah blah blah")
                        .font(.subheadline)
                }
                .frame(width: 200, height: 80)
                .padding()
                Spacer()
                VStack {
                    if plan == selectedPlan {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 30, height: 30, alignment: .center)
                .padding()
            }
            .foregroundColor(textColor)
            .frame(width: 300, height: 100)
            .background(background)
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
    }
}

struct SubscriptionLevelForm: View {
    @Binding var selectedPlan: String
    let plans = ["Basic", "Standard", "Premium"]

    var body: some View {
        VStack {
            Text("Choose a subscription")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            //Spacer()

            ForEach(plans, id: \.self) { plan in
                SubscriptionCard(plan: plan, selectedPlan: $selectedPlan)
            }

            Spacer()

            Button(action: {}) {
                Text("Sign Up for \(selectedPlan)")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    //.background(Color.accentColor)
                    //.background(LinearGradient(gradient: Gradient(colors: [Color.blue, SubscriptionCard.colors[selectedPlan] ?? Color.accentColor]), startPoint: .leading, endPoint: .trailing))
                    .background(SubscriptionCard.colors[selectedPlan] ?? Color.accentColor)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}



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

    //@Binding var selectedScreen: LoggedOutScreen.Screen
    /*
    @State var selectedPlan: String = "Standard"
    @State var selectedTerm: Int = 1
    let terms = [1, 6, 12]
    */

    @State var selectedProduct: SKProduct?

    /*
    func getProducts() {
        var identifiers = Set<String>()
        guard let storefront = SKPaymentQueue.default().storefront else {
            print("STOREKIT\tError: Couldn't get storefront")
            return
        }
        //for (identifier, _) in
    }
    */

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

    var body: some View {
        VStack {
            buttonBar

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
