//
//  ForgotPasswordView.swift
//  Circles
//
//  Created by Charles Wright on 3/25/24.
//

import SwiftUI
import Matrix

func passwordResetFilter(flow: AuthFlow) -> Bool {
    // Poor man's subsequence
    if let uia = flow as? UIAA.Flow {
        CirclesApp.logger.debug("passwordResetFilter: Got stages = \(uia.stages)")
        if let i1 = uia.stages.firstIndex(of: AUTH_TYPE_LOGIN_EMAIL_REQUEST_TOKEN),
           let i2 = uia.stages.firstIndex(of: AUTH_TYPE_LOGIN_EMAIL_SUBMIT_TOKEN),
           let i3 = uia.stages.firstIndex(of: AUTH_TYPE_ENROLL_BSSPEKE_OPRF),
           let i4 = uia.stages.firstIndex(of: AUTH_TYPE_ENROLL_BSSPEKE_SAVE)
        {
            CirclesApp.logger.debug("passwordResetFilter: Match!")
            return i1 < i2 && i2 < i3 && i3 < i4
        } else {
            CirclesApp.logger.debug("passwordResetFilter: Mismatch")
            return false
        }
    } else {
        CirclesApp.logger.debug("passwordResetFilter: Not UIA - mismatch")
        return false
    }
    
}

struct ForgotPasswordView: View {
    @ObservedObject var store: CirclesStore
    @State var username: String = ""
    @FocusState var inputFocused

    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    
    @State var showUsernameError = false
    
    var body: some View {
        VStack {

            CirclesLogoView()
                .frame(minWidth: 100,
                       idealWidth: 150,
                       maxWidth: 240,
                       minHeight: 100,
                       idealHeight: 150,
                       maxHeight: 240,
                       alignment: .center)
            
            Spacer()
            
            Text("Account Recovery")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text("Enter your username to begin")
            
            TextField("@user:example.com", text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($inputFocused)
                .frame(width: 300.0, height: 40.0)
                .onAppear {
                    self.inputFocused = true
                }
            
            AsyncButton(action: {
                if !username.isEmpty {
                    if let userId = UserId(username) {
                        try await store.login(userId: userId, filter: passwordResetFilter)
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
                Text("Reset Password and Log In")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .confirmationDialog("It looks like maybe you mis-typed your username",
                                isPresented: $showSuggestion,
                                presenting: suggestedUserId,
                                actions: { userId in
                                    AsyncButton(action: {
                                        try await store.login(userId: userId, filter: passwordResetFilter)
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
            .padding()
            
            Spacer()
        }
        .navigationTitle(Text("Forgot Password"))
    }
}
