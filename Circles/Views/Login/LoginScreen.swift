//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoginScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/30/20.
//

import SwiftUI
import StoreKit

struct LoginScreen: View {
    var matrix: MatrixInterface
    //@Binding var selectedScreen: LoggedOutScreen.Screen
    @Binding var uiaaState: UiaaSessionState?

    @EnvironmentObject var appStore: AppStoreInterface


    @State var username: String = ""
    @State var password: String = ""
    @State var password2: String = ""

    @State var pendingLogin = false
    @State var pendingSignup = false

    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var showAdvanced = false
    @State var showPassword = false
    
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

    func login() {

        if self.username.isEmpty {
            print("LoginScreen\tGot empty username; Ignoring...")
            return
        }

        if self.password.isEmpty {
            print("LoginScreen\tGot empty password; Ignoring...")
            return
        }

        self.pendingLogin = true

        if self.password2.isEmpty {
            self.matrix.login(username: self.username, rawPassword: self.password, s4Password: nil) { response in
                self.pendingLogin = false
                if response.isFailure {
                    self.alertTitle = "Login Failed"
                    self.alertMessage = "Bad username or password?"
                    self.showAlert = true
                    self.password = ""
                    self.password2 = ""
                }
            }
        } else {
            self.matrix.login(username: self.username, rawPassword: self.password, s4Password: password2) { response in
                self.pendingLogin = false
                if response.isFailure {
                    self.alertTitle = "Login Failed"
                    self.alertMessage = "Bad username or password?"
                    self.showAlert = true
                    self.password = ""
                    self.password2 = ""
                }
            }
        }
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
            
            TextField("Username", text: $username)
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)

            SecureFieldWithEye(label: "Password", text: $password)
                .frame(width: 300.0, height: 40.0)

            VStack(alignment: .leading) {
                HStack {
                    Button(action: {self.showAdvanced.toggle()}) {
                        if showAdvanced {
                            Label("Hide Advanced Options", systemImage: "chevron.down")

                        } else {
                            Label("Advanced Options", systemImage: "chevron.right")
                        }
                    }
                    .font(.footnote)

                    Spacer()
                }
                .frame(width: 300.0, height: 30.0)

                if showAdvanced {
                    SecureFieldWithEye(label: "Encryption password", text: $password2)
                        .frame(width: 300.0, height: 30.0)
                }
            }



            Button(action: login) {
                Text("Log In")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(pendingLogin)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login failed"),
                      message: Text("Bad username or password?"),
                      dismissButton: .cancel(Text("OK"))
                )
            }
            
            Spacer()
            
            Text("Not a member?")
            Button(action: {

                if let countryCode = SKPaymentQueue.default().storefront?.countryCode {
                    print("LOGIN\tGot country code = \(countryCode)")
                } else {
                    print("LOGIN\tFailed to get country code from StoreKit")
                }

                self.pendingSignup = true
                
                self.matrix.startNewSignupSession { response in
                    /*
                    if response.isSuccess {
                        self.selectedScreen = .signupMain
                    }
                    */
                    switch response {
                    case .failure(let err):
                        print("Failed to start new signup session: \(err)")
                    case .success(let newUiaaSession):
                        self.uiaaState = newUiaaSession
                    }
                    self.pendingSignup = false
                }
            }) {
                Text("Sign Up")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled( pendingSignup )
            .padding(.bottom)


        }
        .padding(.horizontal)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }

    }

}

/*
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(matrix: KSStore())
    }
}
*/
