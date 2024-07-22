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

struct NewLoginScreen: View {
    var store: CirclesStore
    @State var username = ""
    @State var password = ""
    @State var showPassword = false
    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    @State var showUsernameError = false
    @Binding var showDomainPicker: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                let buttonWidth = UIScreen.main.bounds.width - 24 * 2
                let buttonHeight: CGFloat = 48.0
                
                Image(SystemImages.launchLogoPurple.rawValue)
                    .padding(.top, 124)
             
                VStack(alignment: .leading) {
                    Text("Your User ID")
                        .bold()
                        .font(.callout)
                                                            
                    TextField("@username:us.domain.com", text: self.$username)
                        .frame(width: buttonWidth - 12, height: buttonHeight)
                        .padding([.horizontal], 6)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "DEE1E6"))) // Color.grey400
                }
                
                VStack(alignment: .leading) {
                    Text("Password")
                        .bold()
                        .font(.callout)
                    
                    SecureFieldWithEye(label: "Password", height: buttonHeight, text: $password, showText: showPassword)
                        .textContentType(.password)
                        .frame(width: buttonWidth, height: buttonHeight)
//                        .padding([.horizontal], 6)
//                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "DEE1E6"))) // Color.grey400
//                        .onAppear {
                            // Attempt to load the saved password that Matrix.swift should have saved in our Keychain
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
                            .font(.subheadline)
                    }
                    .padding(5)
                }
                
                Spacer()
                
                let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                              height: buttonHeight,
                                                              color: Color(hex: "8553FF")) // == Color.primary800
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
                .bold()
                .font(.title3)
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
                    Button("Sign Up here") {
                        self.showDomainPicker = true
                    }
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal)
        }
    }
}

struct NewWelcomeScreen: View {
    var store: CirclesStore
    @State var showDomainPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("launchcirclebackground")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(SystemImages.launchLogoPurple.rawValue)
                        .padding(.top, 124)
                    
                    Text("The secure social network for families and friends")
                        .bold()
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white)
                    
                    Spacer()
                    
                    let buttonWidth = UIScreen.main.bounds.width - 24 * 2
                    let buttonHeight: CGFloat = 48.0
                    let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                  height: buttonHeight,
                                                                  color: Color(hex: "8553FF")) // == Color.primary800
                                        
                    Button(action: {
                        self.showDomainPicker = true
                    }) {
                        Text("Sign Up for free")
                            .bold()
                            .font(.title3)
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
                    NavigationLink(destination: NewLoginScreen(store: store, showDomainPicker: $showDomainPicker)) {
                        Text("Sign In")
                    }
                    .buttonStyle(signInButtonStyle)
                    .bold()
                    .font(.title3)
                    .padding(.bottom, 48)
                }
            }
            .background(Color.clear)
        }
    }
}

/*
struct WelcomeScreen: View {
    var store: CirclesStore
    
    @AppStorage("previousUserIds") var previousUserIds: [UserId] = []
    
    @FocusState var inputFocused
    @State var showingKeyboard = false
        
    @State var username: String = ""
    @State var showDomainPicker = false
    
    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    
    @State var showUsernameError = false
            
    // Inspired by https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
    private var keyboardPublisher: AnyPublisher<CGFloat,Never> {
        Publishers.Merge(
            NotificationCenter.default
                              .publisher(for: UIResponder.keyboardWillShowNotification)
                              .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                              .map { $0.height },
            NotificationCenter.default
                              .publisher(for: UIApplication.keyboardWillHideNotification)
                              .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    @ViewBuilder
    var welcomeView: some View {
        VStack(alignment: .center) {
                    
            CirclesLogoView()
                .frame(minWidth: 100,
                       idealWidth: 200,
                       maxWidth: 300,
                       minHeight: 100,
                       idealHeight: 200,
                       maxHeight: 300,
                       alignment: .center)
            
            Text("FUTO Circles")
                .font(.largeTitle)
                .fontWeight(.bold)
            /*
            Text("by FUTO Labs")
                .font(.headline)
                .fontWeight(.bold)
            */
            
            TextField("@user:example.com", text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($inputFocused)
                .frame(width: 300.0, height: 40.0)
                .textFieldStyle(RoundedBorderTextFieldStyle())

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
            .buttonStyle(BigRoundedButtonStyle())
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

            if showingKeyboard {
                Spacer()
                Button(role: .destructive, action: {
                    self.inputFocused = false
                }) {
                    Text("Cancel")
                        .padding()
                }
            } else {
                
                NavigationLink(destination: ForgotPasswordView(store: store)) {
                    Text("Forgot password?")
                        .font(.subheadline)
                }
                .padding(5)
                
                if !previousUserIds.isEmpty {

                    VStack {
                        HStack {
                            Text("Log in again")
                                .font(.body.smallCaps())
                                .foregroundColor(.gray)
                                .padding(.leading)
                            Spacer()
                        }
                        ForEach(previousUserIds) { userId in
                            
                            HStack {
                                AsyncButton(action: {
                                    try await store.login(userId: userId, filter: loginFilter)
                                    await MainActor.run {
                                        self.suggestedUserId = nil
                                    }
                                }) {
                                    Text(userId.stringValue)
                                        .lineLimit(1)
                                }
                                //.buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button(action: {
                                    let otherUserIds = previousUserIds.filter { $0 != userId }
                                    self.previousUserIds = otherUserIds
                                }) {
                                    Image(systemName: SystemImages.xmark.rawValue)
                                }
                            }
                            .padding()
                            .background {
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.30))
                                    //.padding(1)
                            }
                            .font(.caption)
                        }
                    }
                    .frame(maxWidth: 300)
                }
                
                Spacer()
                
                Text("Need an account?")
                Button(action: {
                    self.showDomainPicker = true
                }) {
                    Text("Sign Up")
                }
                .buttonStyle(BigRoundedButtonStyle())
                .padding(.bottom, 20)
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
        }
        //.padding(.horizontal)
        /*
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        */
        .onReceive(keyboardPublisher) {
            if $0 == 0 {
                self.showingKeyboard = false
            } else {
                self.showingKeyboard = true
            }
        }
    }

    var body: some View {
        NavigationStack {
            welcomeView
        }
    }
}
*/
