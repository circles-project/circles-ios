//
//  SecretStoragePasswordScreen.swift
//  Circles
//
//  Created by Charles Wright on 8/16/23.
//

import SwiftUI
import Matrix
import IDZSwiftCommonCrypto

struct SecretStoragePasswordScreen: View {
    var store: CirclesStore
    @ObservedObject var matrix: Matrix.Session
    var keyId: String
    var description: Matrix.KeyDescriptionContent
    
    @State var useRawKey = false
    
    @State var password = ""
    @State var base58Key = ""
    
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertTitle = ""
    
    var canUsePassphrase: Bool {
        guard let info = description.passphrase
        else {
            return false
        }
        return info.algorithm == M_PBKDF2
    }
    
    @ViewBuilder
    var passwordInputView: some View {
        VStack {
            Text("Please enter your passphrase for secure backup and recovery")
                .font(.title2)
            
            Text("Note: This passphrase is typically not the same as your login password")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
            
            SecureField("correct horse battery staple", text: $password, prompt: Text("Passphrase"))
                .frame(width: 300.0, height: 40.0)
            
            AsyncButton(action: {
                if password.isEmpty {
                    return
                }
                
                guard let ssss = matrix.secretStore,
                      let key = try ssss.generateKey(keyId: keyId, password: password, description: description)
                else {
                    print("Boo: PBKDF2 key doesn't match :-(")
                    self.showAlert = true
                    self.alertMessage = "Failed to enable secret storage"
                    self.alertTitle = "Key generation failed"
                    return
                }
                CirclesApp.logger.debug("Generated key base58 = \(key.base58String)")
                print("Yay! PBKDF2 key matches!")
                try await store.addMissingKey(key: key)
            }) {
                Text("Submit")
                    .customTextInButtonStyle()
            }
            
            Button(action: {
                self.useRawKey = true
            }) {
                Text("I don't remember my recovery passphrase")
            }
            .padding()
        }
    }
    
    @ViewBuilder
    var rawKeyInputView: some View {
        VStack {
            Text("Please enter the secure backup key for this account")
                .font(.title2)
            
            TextField("Backup key", text: $base58Key, prompt: Text("abcd 1234 wxyz 4567 ..."))
            
            AsyncButton(action: {
                
                CirclesApp.logger.debug("Key description: Algorithm = \(description.algorithm)")
                if let info = description.passphrase {
                    CirclesApp.logger.debug("Passphrase: Algorithm = \(info.algorithm)  Bits = \(info.bits ?? 0)")
                }
                
                guard let key = try? Matrix.SecretStorageKey(raw: base58Key, keyId: keyId, description: description)
                else {
                    await MainActor.run {
                        self.base58Key = ""
                        self.alertTitle = "Invalid backup key"
                        self.alertMessage = "There was an error processing your backup key.  Please double check your key and try again."
                        self.showAlert = true
                    }
                    return
                }
                CirclesApp.logger.debug("Created SSSS key \(keyId)")
                
                try await store.addMissingKey(key: key)
                CirclesApp.logger.debug("Added SSSS key \(keyId)")
            }) {
                Text("Submit")
                    .customTextInButtonStyle()
            }
            .disabled(base58Key.isEmpty)
            
            Button(action: {
                self.useRawKey = false
            }) {
                Text("Use recovery passphrase instead")
            }
            .disabled(canUsePassphrase == false)
            .padding()
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            CirclesLogoView()
                .frame(minWidth: 60,
                       idealWidth: 90,
                       maxWidth: 120,
                       minHeight: 60,
                       idealHeight: 90,
                       maxHeight: 120,
                       alignment: .center)
            
            Spacer()
            
            if useRawKey == false,
               canUsePassphrase == true
            {
               passwordInputView
            } else {
                rawKeyInputView
            }
            
            AsyncButton(role: .destructive, action: {
                try await store.logout()
            }) {
                Text("Cancel")
                    .customTextInButtonStyle()
            }
            .alert(self.alertTitle,
                   isPresented: $showAlert,
                   actions: {
                        Button(action: {
                            self.password = ""
                            self.base58Key = ""
                        }) {
                            Text("Try again")
                        }
                   },
                   message: {
                       Text(alertMessage)
                   }
            )
            
            Spacer()
            
            if DebugModel.shared.debugMode {
                VStack(alignment: .leading) {
                    Text("Info")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Algorithm: \(description.algorithm)")
                    if let info = description.passphrase {
                        Text("Password hashing:")
                        VStack(alignment: .leading) {
                            Text("Algorithm: \(info.algorithm)")
                            Text("Salt: \(info.salt ?? "n/a")")
                        }
                        .padding(.leading, 10)
                    }
                }
            }
        }
        .padding()
    }
    
}

/*
struct SecretStoragePasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        SecretStoragePasswordScreen()
    }
}
*/
