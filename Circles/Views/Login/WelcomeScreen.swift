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
    
    private var backButton: some View {
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
                        Text("Next step")
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
                    .disabled(username.isEmpty)
                    
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

struct DomainScreen: View {
    #if DEBUG 
    @State var domain: String = usDomain
    #else
    @State var domain: String = ""
    #endif
    var store: CirclesStore
    
    @FocusState var inputFocused
    @Environment(\.presentationMode) var presentation
    
    private var backButton: some View {
        Button(role: .destructive, action: {
            Task {
                try await self.store.disconnect()
            }
            self.presentation.wrappedValue.dismiss()
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
        let screenWidthWithOffsets = UIScreen.main.bounds.width - 48
        
        ZStack {
            Color.greyCool200
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                
                BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                    .frame(width: 125, height: 43)
                    .padding(.bottom, 30)
                
                VStack(alignment: .leading) {
                    Text("Enter your domain address")
                        .font(
                            CustomFonts.nunito14
                                .weight(.bold)
                        )
                        .foregroundColor(Color.greyCool1100)
                    
                    TextField("us.domain.com", text: $domain)
                        .frame(width: screenWidthWithOffsets, height: 48.0)
                        .padding([.horizontal], 12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.greyCool400))
                        .focused($inputFocused)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onAppear {
                            self.inputFocused = true
                        }
                }
                
                Spacer()
                
                AsyncButton(action: {
                    try await store.signup(domain: usDomain)
                }) {
                    Text("Use this domain")
                        .foregroundStyle(Color.white)
                }
                .frame(width: screenWidthWithOffsets, height: 48)
                .background(Color.accentColor)
                .cornerRadius(8)
                .font(
                    CustomFonts.nunito16
                        .weight(.bold)
                )
                .padding(.bottom, 38)
                .disabled(domain.isEmpty)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct WelcomeScreen: View {
    var store: CirclesStore
    @State var showDomainPicker = false
    @AppStorage("showDescriptionText") var showDescriptionText = false
    
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
                    
                    HStack {
                        Spacer()
                        Button("About this app") {
                            showDescriptionText = true
                        }
                        .font(
                            CustomFonts.nunito16
                                .weight(.bold)
                        )
                        .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, 24)
                    
                    let buttonWidth = UIDevice.isPad ? 400 : UIScreen.main.bounds.width - 24 * 2
                    let buttonHeight: CGFloat = 48.0
                    let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: Color.accentColor)
                    
                    NavigationLink(destination: DomainScreen(store: store)) {
                        Text("Create an account")
                            .font(
                                CustomFonts.nunito16
                                    .weight(.bold)
                            )
                    }
                    .buttonStyle(signUpButtonStyle)
                    .font(
                        CustomFonts.nunito16
                            .weight(.bold)
                    )
                    
                    let signInButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: .clear,
                                                                  borderWidth: 1)
                    NavigationLink(destination: LoginScreen(store: store, showDomainPicker: $showDomainPicker)) {
                        Text("Log In")
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
            .sheet(isPresented: $showDescriptionText) {
                VStack {
                    AppHelpView()

                    Button(action: {self.showDescriptionText = false}) {
                        Label("Got it", systemImage: "hand.thumbsup.fill")
                            .padding()
                    }
                    .buttonStyle(BigRoundedButtonStyle())
                    Spacer()
                }
            }
        }
    }
}
