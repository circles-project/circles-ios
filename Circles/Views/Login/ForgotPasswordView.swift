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
    @Environment(\.presentationMode) var presentationMode
    @State var username: String = ""
    @FocusState var inputFocused

    @State var showSuggestion = false
    @State var suggestedUserId: UserId? = nil
    
    @State var showUsernameError = false
    
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
            
            VStack {
                let buttonWidth = UIScreen.main.bounds.width - 48
                let buttonHeight: CGFloat = 48.0
                
                HStack {
                    backButton
                    Spacer()
                }
                
                BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                    .frame(width: 125, height: 43)
                    .padding(.bottom, 30)
                
                Text("Account Recovery")
                    .font(
                        CustomFonts.nunito20
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading) {
                    Text("Enter your username to begin")
                        .font(
                            CustomFonts.nunito14
                                .weight(.bold)
                        )
                        .foregroundColor(Color.greyCool1100)
                    
                    TextField("@user:example.com", text: $username)
                        .frame(width: buttonWidth, height: buttonHeight)
                        .padding([.horizontal], 12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.greyCool400))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($inputFocused)
                        .onAppear {
                            self.inputFocused = true
                        }
                }
                
                Spacer()
                
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
                }
                .buttonStyle(BigRoundedButtonStyle(width: buttonWidth, height: buttonHeight))
                .font(
                    CustomFonts.nunito16
                        .weight(.bold)
                )
                .padding(.bottom, 38)
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
            }
        }
        .navigationBarBackButtonHidden()
    }
}
