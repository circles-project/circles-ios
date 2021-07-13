//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SignupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import StoreKit

struct SignupScreen: View {
    var matrix: MatrixInterface
    @Binding var selectedScreen: LoggedOutScreen.Screen

    var cancel: some View {
        HStack {
            Button(action: {
                self.selectedScreen = .login
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

            Text("Sign up for Circles")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Spacer()

            Text("Already have a Circles token?")
            Button(action: {
                selectedScreen = .tokenSignup
            }) {
                Text("Sign up with token")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

            Spacer()

            /*
            Text("No token?  No problem.")
            Button(action: {
                selectedScreen = .appstoreSignup
            }) {
                Text("New Circles subscription")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled( !SKPaymentQueue.canMakePayments() )

            Spacer()
            */
        }
    }
}

/*
struct SignupScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
