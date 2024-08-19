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

    @State var passphrase: String = ""
    @State var failed = false
    var showPassword = false

    @ViewBuilder
    var oprfForm: some View {
        VStack {
            Spacer()
            
            Text("Enter your passphrase")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack {
                SecureFieldWithEye(password: $passphrase,
                                   placeholder: "Passphrase")
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
    var verifyForm: some View {
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

    var body: some View {
        if stage == AUTH_TYPE_LOGIN_BSSPEKE_VERIFY {
            verifyForm
        } else {
            oprfForm
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
