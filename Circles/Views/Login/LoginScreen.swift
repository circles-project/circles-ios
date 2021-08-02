//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoginScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/30/20.
//

import SwiftUI

struct LoginScreen: View {
    var matrix: MatrixInterface
    @Binding var selectedScreen: LoggedOutScreen.Screen

    @State var username: String = ""
    @State var password: String = ""
    @State var password2: String = ""

    @State var pending = false
    @State var showAlert = false
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
    
    var body: some View {
        VStack(alignment: .center) {
                    
            logo
            
            Text("Kombucha.social")
                .font(.headline)
                .fontWeight(.bold)
            Text("Circles")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .keyboardType(.emailAddress)
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)

            EyeSecureField(label: "Password", text: $password)
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
                    EyeSecureField(label: "Encryption password", text: $password2)
                        .frame(width: 300.0, height: 30.0)
                }
            }



            Button(action: {
                self.pending = true
                if self.password2.isEmpty {
                    self.matrix.login(username: self.username, rawPassword: self.password, s4Password: nil) { response in
                        self.pending = false
                        if response.isFailure {
                            self.showAlert = true
                            self.password = ""
                            self.password2 = ""
                        }
                    }
                } else {
                    self.matrix.login(username: self.username, rawPassword: self.password, s4Password: password2) { response in
                        self.pending = false
                        if response.isFailure {
                            self.showAlert = true
                            self.password = ""
                            self.password2 = ""
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
            .disabled(pending)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login failed"),
                      message: Text("Bad username or password?"),
                      dismissButton: .cancel(Text("OK"))
                )
            }
            
            Spacer()
            
            Text("Not a member?")
            Button(action: {
                self.matrix.startNewSignupSession { response in
                    if response.isSuccess {
                        self.selectedScreen = .signupMain
                    }
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
    }

}

/*
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(matrix: KSStore())
    }
}
*/
