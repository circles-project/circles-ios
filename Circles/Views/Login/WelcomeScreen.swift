//
//  WelcomeScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/8/22.
//

import SwiftUI
import Combine
import StoreKit
import Matrix
//import KeychainAccess

func loginFilter(flow: AuthFlow) -> Bool {
    // If it's a UIA flow, we want BS-SPEKE login
    if let uiaFlow = flow as? UIAA.Flow {
        return uiaFlow.stages.contains(AUTH_TYPE_LOGIN_BSSPEKE_OPRF) && uiaFlow.stages.contains(AUTH_TYPE_LOGIN_BSSPEKE_VERIFY)
    }
    // If it's a legacy (standard) Matrix login, we want m.login.password
    if let legacyFlow = flow as? Matrix.StandardLoginFlow {
        return legacyFlow.type == M_LOGIN_PASSWORD
    }
    // Otherwise we don't know what the hell this thing is
    return false
}

struct LoginScreen: View {
    var store: CirclesStore
    @Environment(\.presentationMode) var presentationMode
    
    @State var username = ""
    @State var password = ""
    @State var showPassword = false
    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    @State var showUsernameError = false
    @Binding var showDomainPicker: Bool
    
    var backButton: some View {
        Button(role: .destructive, action: {
            Task {
                try await self.store.disconnect()
            }
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(SystemImages.iconFilledArrowBack.rawValue)
                .padding(5)
                .frame(width: 40.0, height: 40.0)
        }
        .background(Color.white)
        .clipShape(Circle())
        .padding(.leading, 21)
        .padding(.top, 65)
    }
    
    var body: some View {
        ZStack {
            Color.greyCool200
                .edgesIgnoringSafeArea(.all)
            
            NavigationStack {
                VStack {
                    HStack {
                        backButton
                        Spacer()
                    }
                    
                    let buttonWidth = UIScreen.main.bounds.width - 48
                    let buttonHeight: CGFloat = 48.0
                                            
                    BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                        .frame(width: 125, height: 43)
                        .padding(.bottom, 30)
                    
                    VStack(alignment: .leading) {
                        Text("Your User ID")
                            .font(
                                CustomFonts.nunito14
                                    .weight(.bold)
                            )
                            .foregroundColor(Color.greyCool1100)
                        
                        TextField("@username:us.domain.com", text: self.$username)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .padding([.horizontal], 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.greyCool400))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Text("Password")
                            .font(
                                CustomFonts.nunito14
                                    .weight(.bold)
                            )
                            .foregroundColor(Color.greyCool1100)
                        
                        SecureFieldWithEye(label: "",
                                           height: buttonHeight,
                                           text: $password,
                                           showText: showPassword,
                                           isFirstResponder: false)
                        .textContentType(.password)
                        .frame(width: buttonWidth, height: buttonHeight)
//                        .padding([.horizontal], 6)
//                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "DEE1E6"))) // Color.grey400
//                        .onAppear {
//                            Attempt to load the saved password that Matrix.swift should have saved in our Keychain
//                            let keychain = Keychain(server: "https://\(session.username.domain)", protocolType: .https)
//                            keychain.getSharedPassword(session.username.stringValue) { (passwd, error) in
//                                if self.password.isEmpty,
//                                   let savedPassword = passwd
//                                {
//                                    self.password = savedPassword
//                                }
//                            }
//                        }
                        NavigationLink(destination: ForgotPasswordView(store: store)) {
                            Text("Forgot?")
                                .font(
                                    CustomFonts.nunito14
                                        .weight(.bold)
                                )
                        }
                        .padding(5)
                    }
                    
                    Spacer()
                    
                    let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: Color.accentColor)
                    AsyncButton(action: {
                        if !username.isEmpty {
                            if let userId = UserId(username) {
                                try await store.login(userId: userId, filter: loginFilter)
                            } else {
                                if let suggestion = UserId.autoCorrect(username, domain: store.defaultDomain) {
                                    self.suggestedUserId = suggestion
                                    self.showSuggestion = true
                                } else {
                                    self.showUsernameError = true
                                }
                            }
                        }
                    }) {
                        Text("Log In")
                    }
                    .buttonStyle(signUpButtonStyle)
                    .font(
                        CustomFonts.nunito16
                            .weight(.bold)
                    )
                    .padding(.bottom, 27)
                    .confirmationDialog("It looks like maybe you mis-typed your user id",
                                        isPresented: $showSuggestion,
                                        presenting: suggestedUserId,
                                        actions: { userId in
                        AsyncButton(action: {
                            try await store.login(userId: userId, filter: loginFilter)
                            await MainActor.run {
                                self.suggestedUserId = nil
                            }
                        }) {
                            Text("Log in as \(userId.stringValue)")
                        }
                        Button(role: .cancel, action: {}) {
                            Text("No, let me try again")
                        }
                    },
                                        message: { userId in
                        Text("Did you mean \(userId.stringValue)?")
                    })
                    .alert(isPresented: $showUsernameError) {
                        Alert(title: Text("Invalid User ID"),
                              message: Text("Circles user ID's should start with an @ and have a domain at the end, like @username:example.com"))
                    }
                    
                    HStack {
                        Text("Don't have an account?")
                            .font(CustomFonts.outfit14)
                        Button("Sign Up here") {
                            self.showDomainPicker = true
                        }
                        .font(CustomFonts.outfit14)
                    }
                    .padding(.bottom, 38)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct WelcomeScreen: View {
    var store: CirclesStore
    @State var showDomainPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image(SystemImages.launchCircleBackground.rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(SystemImages.launchLogoPurple.rawValue)
                        .padding(.top, 124)
                    
                    Text("The secure social network for families and friends")
                        .font(
                            CustomFonts.nunito24
                                .weight(.bold)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 36)
                    
                    Spacer()
                    
                    let buttonWidth = UIDevice.isPad ? 400 : UIScreen.main.bounds.width - 24 * 2
                    let buttonHeight: CGFloat = 48.0
                    let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: Color.accentColor)
                    
                    Button(action: {
                        self.showDomainPicker = true
                    }) {
                        Text("Sign Up for free")
                            .font(
                                CustomFonts.nunito16
                                    .weight(.bold)
                            )
                    }
                    .buttonStyle(signUpButtonStyle)
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
                    
                    let signInButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: .clear,
                                                                  borderWidth: 1)
                    NavigationLink(destination: LoginScreen(store: store, showDomainPicker: $showDomainPicker)) {
                        Text("Sign In")
                    }
                    .buttonStyle(signInButtonStyle)
                    .font(
                        CustomFonts.nunito16
                            .weight(.bold)
                    )
                    .padding(.bottom, 48)
                }
            }
            .background(Color.clear)
        }
    }
}
