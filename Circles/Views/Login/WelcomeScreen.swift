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
    
    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    
    @State var showUsernameError = false
    
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
    
    // Try to create a valid UserId from the given input string
    func suggestUserId(_ input: String) -> UserId? {
        // If we already have a valid UserId, let's just stick with that
        if let userId = UserId(input) {
            return userId
        }

        // Case 1 - User just forgot the leading "@"
        if !input.localizedStandardContains("@") {
            // Do we have a country code and a default domain?
            guard let countryCode = store.countryCode
            else {
                // If no, then the best we can do is to add the @ and give it a shot
                return UserId("@\(input)")
            }
            
            let domain = store.getOurDomain(countryCode: countryCode)
            
            if !input.contains(":") {
                return UserId("@\(input):\(domain)")
            } else {
                return UserId("@\(input)")
            }
            
        }
        // Case 2 - User transposed their Matrix UserId into an email address
        else if input.localizedStandardContains("@") && !input.starts(with: "@") {
            let toks = input.split(separator: "@")
            guard toks.count == 2,
                  let userpart = toks.first,
                  let domainAndPort = toks.last
            else {
                return nil
            }
            return UserId("@\(userpart):\(domainAndPort)")
        }
        
        // If we didn't match any of the cases above, then we don't know what to do with this one
        return nil
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
                    if let userId = UserId(username) {
                        try await store.login(userId: userId)
                    } else {
                        if let suggestion = suggestUserId(username) {
                            self.suggestedUserId = suggestion
                            self.showSuggestion = true
                        } else {
                            self.showUsernameError = true
                        }
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
            .confirmationDialog("It looks like maybe you mis-typed your user id",
                                isPresented: $showSuggestion,
                                presenting: suggestedUserId,
                                actions: { userId in
                                    AsyncButton(action: {
                                        try await store.login(userId: userId)
                                        await MainActor.run {
                                            self.suggestedUserId = nil
                                        }
                                    }) {
                                        Text("Log in as \(userId.stringValue)")
                                    }
                                },
                                message: { userId in
                                    Text("It looks like you might have mis-typed your user id.  Did you mean \(userId.stringValue)?")
                                }
            )
            .alert(isPresented: $showUsernameError) {
                Alert(title: Text("Invalid User ID"),
                      message: Text("Circles user ID's should start with an @ and have a domain at the end, like @username:example.com"))
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


