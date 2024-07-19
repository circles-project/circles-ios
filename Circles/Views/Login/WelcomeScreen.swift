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
