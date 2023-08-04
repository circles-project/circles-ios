//
//  WelcomeScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/8/22.
//

import SwiftUI
import StoreKit
import Matrix

struct WelcomeScreen: View {
    var store: CirclesStore
    
    @State var username: String = ""
    @State var showDomainPicker = false
    
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
            /*
            Text("by FUTO Labs")
                .font(.headline)
                .fontWeight(.bold)
            */
            
            TextField("@user:example.com", text: $username)
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)


            AsyncButton(action: {
                if !username.isEmpty {
                    guard let userId = UserId(username)
                    else {
                        // Set error message
                        return
                    }

                    do {
                        try await store.login(userId: userId)
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

                /* // Enabling manual testing of the various servers for now
                if let countryCode = await Storefront.current?.countryCode {
                    print("LOGIN\tGot country code = \(countryCode)")
                    let domain = store.getOurDomain(countryCode: countryCode)
                    print("LOGIN\tSigning up on domain \(domain)")
                    try await self.store.signup(domain: domain)
                } else {
                    print("LOGIN\tFailed to get country code from StoreKit")
                    self.showDomainPicker = true
                }
                */
                
                self.showDomainPicker = true
            }) {
                Text("Sign Up")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)
            .confirmationDialog("Select a region", isPresented: $showDomainPicker) {
                AsyncButton(action: {
                    print("LOGIN\tSigning up on user-selected US domain")
                    try await store.signup(domain: usDomain)
                }) {
                    Text("🇺🇸 Sign up on US server")
                }
                AsyncButton(action: {
                    print("LOGIN\tSigning up on user-selected EU domain")
                    try await store.signup(domain: euDomain)
                }) {
                    Text("🇪🇺 Sign up on EU server")
                }
            }


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


