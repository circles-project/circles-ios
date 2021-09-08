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
        let borderColor = Color.accentColor
        //let textColor = self.selectedProduct == nil ? Color.primary : (selected ? Color.primary : Color.gray)
        let backgroundColor = selected ? Color.accentColor : Color.clear

        return Button(action: {
            self.selectedProduct = product
        }) {
            VStack(alignment: .leading) {
                let bigFont = Font.title2
                HStack {
                    Text(product.localizedTitle)
                        .font(bigFont)
                        .fontWeight(.bold)
                    Spacer()
                    if alreadyPurchased {
                        Text ("Purchased")
                            .font(bigFont)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text("\(product.regularPrice!)")
                            .font(bigFont)
                            .fontWeight(.bold)
                            //.foregroundColor(.blue)
                    }
                }

                Text(product.localizedDescription)
                    .font(.subheadline)
            }
            //.foregroundColor(textColor)
            .padding()
            .frame(width: 300, height: 100)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 2))
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(alreadyPurchased)
    }
}

struct AppStoreSignUpScreen: View {
    var matrix: MatrixInterface
    @EnvironmentObject var appStore: AppStoreInterface

    @Binding var selectedScreen: LoggedOutScreen.Screen
    @State var selectedPlan: String = "Standard"
    @State var selectedTerm: Int = 1
    let terms = [1, 6, 12]

    @State var selectedProduct: SKProduct?

    func getProducts() {
        var identifiers = Set<String>()
        guard let storefront = SKPaymentQueue.default().storefront else {
            print("STOREKIT\tError: Couldn't get storefront")
            return
        }
        //for (identifier, _) in
    }


    var buttonBar: some View {
        HStack {
            Button(action: {
                self.selectedScreen = .signupMain
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

    var body: some View {
        VStack {
            buttonBar

            Text("Choose subscription term")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            ForEach(terms, id: \.self) { term in
                Button(action: {
                    self.selectedTerm = term
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(term) months for $X.YY")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Save $X.YZ")
                                .padding(.leading)
                        }
                        .padding(.leading)
                        Spacer()
                    }
                    .frame(width: 300, height: 100)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor, lineWidth: 2))
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }

            let products = appStore.membershipProducts.sorted(by: sortProductsByPrice)
            ForEach(products, id: \.self) { product in
                MembershipProductCard(product: product, selectedProduct: $selectedProduct)
            }

            Spacer()

            Text("Subscriptions will automatically renew until canceled")
                .font(.footnote)
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
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(selectedProduct == nil || appStore.purchased.contains(selectedProduct!.productIdentifier))
            .padding()
        }
    }
}

/*
struct AppStoreSignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreSignUpScreen()
    }
}
*/

#endif
