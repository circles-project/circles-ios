//
//  PasswordLoginForm.swift
//  Circles
//
//  Created by Charles Wright on 1/31/24.
//

import SwiftUI
import Matrix
import KeychainAccess

struct LegacyPasswordUiaForm: View {
    var session: UIAuthSession

    @State var passphrase: String = ""
    @State var errorMessage = ""
    @State var failed = false
    
    enum FocusField {
        case passphrase
    }
    @FocusState var focus: FocusField?
    
    var showErrorMessageView: some View {
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
        VStack {
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
                        // Automatically focus the input field
                        self.focus = .passphrase
                        
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
                
                showErrorMessageView
                AsyncButton(action: {
                    print("Doing m.login.password stage for UIA")
                    do {
                        try await session.doPasswordAuthStage(password: passphrase)
                    } catch {
                        errorMessage = error.localizedDescription
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
        }
    }
}
