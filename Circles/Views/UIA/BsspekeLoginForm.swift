//
//  BsspekeLoginForm.swift
//  Circles
//
//  Created by Charles Wright on 8/7/23.
//

import SwiftUI
import Matrix
import KeychainAccess

struct BsspekeLoginForm: View {
    var session: UIAuthSession
    var stage: String
//    var store: CirclesStore

    @State private var passphrase: String = ""
    @State private var failed = false
    var showPassword = false
    
    @Environment(\.presentationMode) private var presentationMode

    @ViewBuilder
    private var oprfForm: some View {
        VStack {
            Spacer()
            
            Text("Enter your passphrase")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack {
                SecureFieldWithEye(label: "Passphrase", text: $passphrase, showText: showPassword)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(width: 300.0, height: 40.0)
                    .onAppear {
                        if let userId = session.userId {
                            // Attempt to load the saved password that Matrix.swift should have saved in our Keychain
                            let keychain = Keychain(server: "https://\(userId.domain)", protocolType: .https)
                            keychain.getSharedPassword(userId.stringValue) { (password, error) in
                                if self.passphrase.isEmpty,
                                   let savedPassword = password
                                {
                                    self.passphrase = savedPassword
                                }
                            }
                        }
                    }
                AsyncButton(action: {
                    print("Doing BS-SPEKE OPRF stage for UIA")
                    try await session.doBSSpekeLoginOprfStage(password: passphrase)
                }) {
                    Text("Submit")
                }
                .buttonStyle(BigRoundedButtonStyle())
                .disabled(passphrase.isEmpty)
                .alert(isPresented: $failed) {
                    Alert(title: Text("Incorrect Passphrase"),
                          message: Text("Passphrase authentication failed. Please double-check your passphrase and try again."),
                          dismissButton: .default(Text("OK"),
                                                  action: {
                                                    self.passphrase = ""
                                                  })
                    )
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var verifyForm: some View {
        VStack {
            Spacer()
            let text = "Verifying your passphrase"
            ProgressView(text)
            Spacer()
        }
        .onAppear {
            self.failed = false
            Task {
                do {
                    try await session.doBSSpekeLoginVerifyStage()
                } catch {
                    await MainActor.run {
                        self.failed = true
                    }
                }
            }
        }

    }
    
    private var backButton: some View {
        Button(role: .destructive, action: {
//            Task {
//                try await self.store.disconnect()
//            }
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
        if stage == AUTH_TYPE_LOGIN_BSSPEKE_VERIFY {
            verifyForm
        } else {
            NavigationStack {
                ZStack {
                    Color.greyCool200
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        let buttonWidth = UIScreen.main.bounds.width - 48
                        let buttonHeight: CGFloat = 48.0
                        
                        BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                            .frame(width: 125, height: 43)
                            .padding(.bottom, 30)
                        
                        VStack(alignment: .leading) {
                            Text("Password")
                                .font(
                                    CustomFonts.nunito14
                                        .weight(.bold)
                                )
                                .foregroundColor(Color.greyCool1100)
                            
                            SecureFieldWithEye(label: "Passphrase", height: buttonHeight,
                                               text: $passphrase, showText: showPassword)
                            .textContentType(.password)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .onAppear {
                                if let userId = session.userId {
                                    // Attempt to load the saved password that Matrix.swift should have saved in our Keychain
                                    let keychain = Keychain(server: "https://\(userId.domain)", protocolType: .https)
                                    keychain.getSharedPassword(userId.stringValue) { (password, error) in
                                        if self.passphrase.isEmpty,
                                           let savedPassword = password
                                        {
                                            self.passphrase = savedPassword
                                        }
                                    }
                                }
                            }
//                            .padding([.horizontal], 6)
//                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "DEE1E6"))) // Color.grey400
//                            .onAppear {
//                                Attempt to load the saved password that Matrix.swift should have saved in our Keychain
//                                let keychain = Keychain(server: "https://\(session.username.domain)", protocolType: .https)
//                                keychain.getSharedPassword(session.username.stringValue) { (passwd, error) in
//                                    if self.password.isEmpty,
//                                       let savedPassword = passwd
//                                    {
//                                        self.password = savedPassword
//                                    }
//                                }
//                            }
//
//                        TODO: important to have it
//                            NavigationLink(destination: ForgotPasswordView(store: store)) {
//                                Text("Forgot?")
//                                    .font(
//                                        CustomFonts.nunito14
//                                            .weight(.bold)
//                                    )
//                            }
//                            .padding(5)
                        }
                        
                        Spacer()
                        
                        let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                                      height: buttonHeight,
                                                                      color: Color.accentColor)
                        
                        AsyncButton(action: {
                            print("Doing BS-SPEKE OPRF stage for UIA")
                            try await session.doBSSpekeLoginOprfStage(password: passphrase)
                        }) {
                            Text("Submit")
                        }
                        .buttonStyle(signUpButtonStyle)
                        .font(
                            CustomFonts.nunito16
                                .weight(.bold)
                        )
                        .padding(.bottom, 27)
                        .disabled(passphrase.isEmpty)
                        .alert(isPresented: $failed) {
                            Alert(title: Text("Incorrect Passphrase"),
                                  message: Text("Passphrase authentication failed. Please double-check your passphrase and try again."),
                                  dismissButton: .default(Text("OK"),
                                                            action: {
                                                                self.passphrase = ""
                                                            })
                            )
                        }
                    }
                    .padding(.bottom, 38)
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
}

/*
struct BsspekeLoginForm_Previews: PreviewProvider {
    static var previews: some View {
        BsspekeLoginForm()
    }
}
*/
