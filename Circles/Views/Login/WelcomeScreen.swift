//
//  WelcomeScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/8/22.
//

import SwiftUI
import StoreKit

struct WelcomeScreen: View {
    var store: CirclesStore
    
    @State var username: String = ""
    
    var logo: some View {
        RandomizedCircles()
            .clipped()
            .frame(minWidth: 100,
                   idealWidth: 200,
                   maxWidth: 300,
                   minHeight: 100,
                   idealHeight: 200,
                   maxHeight: 300,
                   alignment: .center)
    }
    
    var body: some View {
        VStack(alignment: .center) {
                    
            logo
            
            Text("Circles")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("by FUTO Labs")
                .font(.headline)
                .fontWeight(.bold)
            
            TextField("User ID e.g. @user:example.com", text: $username)
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)


            AsyncButton(action: {
                if !username.isEmpty {
                    do {
                        try await store.login(username: username)
                    } catch {
                        
                    }
                }
            }) {
                Text("Log In")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

            
            Spacer()
            
            Text("Not a member?")
            AsyncButton(action: {

                if let countryCode = SKPaymentQueue.default().storefront?.countryCode {
                    print("LOGIN\tGot country code = \(countryCode)")
                } else {
                    print("LOGIN\tFailed to get country code from StoreKit")
                }

                do {
                    try await self.store.signup()
                } catch {
                    
                }

            }) {
                Text("Sign Up")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.bottom)


        }
        .padding(.horizontal)
        /*
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        */

    }

}


