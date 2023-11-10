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
    
    var body: some View {
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


            AsyncButton(action: {
                if !username.isEmpty {
                    if let userId = UserId(username) {
                        try await store.login(userId: userId)
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
                                    Button(role: .cancel, action: {}) {
                                        Text("No, let me try again")
                                    }
                                },
                                message: { userId in
                                    Text("Did you mean \(userId.stringValue)?")
                                }
            )
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
                
                if !previousUserIds.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Or, log in again")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        ScrollView {
                            ForEach(previousUserIds) { userId in
                                AsyncButton(action: {
                                    try await store.login(userId: userId)
                                    await MainActor.run {
                                        self.suggestedUserId = nil
                                    }
                                }) {
                                    Text("Log in as \(userId.stringValue)")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
                
                Text("Need an account?")
                Button(action: {
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

        }
        .padding(.horizontal)
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

}


