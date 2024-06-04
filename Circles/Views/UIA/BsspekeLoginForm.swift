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
    @State private var errorMessage = ""
    
    enum FocusField {
        case passphrase
    }
    @FocusState var focus: FocusField?

    @ViewBuilder
    var oprfForm: some View {
        VStack {
            showErrorMessageView
            
            Spacer()
            
            Text("Enter your passphrase")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack {
                SecureField("Passphrase", text: $passphrase, prompt: Text("Passphrase"))
                    .textContentType(.password)
                    .focused($focus, equals: .passphrase)
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
                    do {
                        try await session.doBSSpekeLoginOprfStage(password: passphrase)
                    } catch {
                        errorMessage = "error.localizedDescription"
                    }
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
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
            ProgressView {
                Text("Verifying passphrase")
            }
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
    
    private var showErrorMessageView: some View {
        VStack {
            if errorMessage != "" {
                ToastView(titleMessage: errorMessage)
                Text("")
                    .onAppear {
                        errorMessage = ""
                    }
            }
        }
    }

    var body: some View {
        if stage == AUTH_TYPE_LOGIN_BSSPEKE_VERIFY {
            verifyForm
        } else {
            oprfForm
                .onAppear {
                    self.focus = .passphrase
                }
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
