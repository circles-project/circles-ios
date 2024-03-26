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
    
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State var password = ""
    @State var base58Key = ""
    
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertTitle = ""
    
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
            
            if let info = description.passphrase,
               info.algorithm == M_PBKDF2
            {
                
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
                    print("Yay! PBKDF2 key matches!")
                    try await store.addMissingKey(key: key)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                
            } else {
                Text("Please enter the secure backup key for this account")
                    .font(.title2)
                
                TextField("abcd 1234 wxyz 4567 ...", text: $base58Key, prompt: Text("Backup key"))
                
                AsyncButton(action: {
                    
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
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(base58Key.isEmpty)
            }
            
            AsyncButton(role: .destructive, action: {
                try await store.logout()
            }) {
                Text("Cancel")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                //.foregroundColor(.white)
                //.background(Color.red)
                    .cornerRadius(10)
            }
            .alert(self.alertTitle,
                   isPresented: $showAlert,
                   actions: {
                        Button(action: {
                            self.password = ""
                        }) {
                            Text("Try again")
                        }
                
                        AsyncButton(role: .cancel, action: {
                            try await store.logout()
                        }) {
                            Text("Cancel")
                        }
                   },
                   message: {
                       Text(alertMessage)
                   }
            )
            
            Spacer()
            
            if debugMode {
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
