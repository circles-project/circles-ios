//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  AppStoreSignUpScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI

struct SubscriptionCard: View {
    let plan: String
    @Binding var selectedPlan: String

    let colors = ["Basic": Color.pink, "Standard": Color.green, "Premium": Color.purple]

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
        colors[plan] ?? Color.accentColor
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

struct AppStoreSignUpScreen: View {
    var matrix: MatrixInterface
    @Binding var selectedScreen: LoggedOutScreen.Screen
    let plans = ["Basic", "Standard", "Premium"]
    @State var selectedPlan: String = "Standard"

    var cancel: some View {
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
        }

    }

    var body: some View {
        VStack {
            cancel

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
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
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
