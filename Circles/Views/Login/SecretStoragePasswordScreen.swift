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
    var description: KeyDescriptionContent
    
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State var password = ""
    @State var showAlert = false
    @State var alertMessage = ""
    @State var alertTitle = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Image("circles-icon-transparent")
                .resizable()
                .scaledToFit()
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
                
                Text("Circles needs your passphrase to enable secret storage for this account")
                    .font(.title2)
                
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
                        return
                    }
                    print("Yay! PBKDF2 key matches!")
                    try await store.finishConnecting(key: key)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .alert("Key generation failed",
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
                
            } else {
                Label("Sorry, Circles cannot connect to the secret storage in this account", systemImage: "exclamationmark.triangle")
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
    
    func generateBcryptKey() throws -> Data? {
        let algorithm = description.passphrase?.algorithm ?? ORG_FUTO_BCRYPT_SHA2
        let iterations = description.passphrase?.iterations ?? 14
        let bitLength = description.passphrase?.bits ?? 256

        guard let salt = description.passphrase?.salt
        else {
            Matrix.logger.error("Can't generate secret storage key without algorithm and iterations")
            return nil
        }
        print("BCRYPT\tRaw salt = \(salt)  (length = \(salt.count))")
        
        let username = matrix.creds.userId.username.dropFirst()
        print("BCRYPT\tUsername = \(username)")
        let rounds = iterations
        print("BCRYPT\tIterations = \(iterations)")
        
        print("BCRYPT\tPassword = \(password)")
        
        let bcryptSalt = "$2a$\(rounds)$\(salt)"
        print("BCRYPT\tSalt = [\(bcryptSalt)]")
        
        guard let bcrypt = try? BCrypt.Hash(password, salt: bcryptSalt)
        else {
            Matrix.logger.error("Failed to compute BCrypt hash")
            throw Matrix.Error("Failed to compute BCrypt hash")
        }
        print("BCRYPT\tGot bcrypt hash = \(bcrypt)")
        
        let root = String(bcrypt.suffix(31))
        print("BCRYPT\tGot bcrypt root = \(root)")
        /*
        let keyData = SHA256.hash(data: "S4Key|\(root)".data(using: .utf8)!)
            .withUnsafeBytes {
                Data(Array($0))
            }
        */
        guard let keyBytes = Digest(algorithm: .sha256).update(string: "S4Key|\(root)")?.final()
        else {
            Matrix.logger.error("Failed to hash the bcrypt root")
            throw Matrix.Error("Failed to hash the bcrypt root")
        }
        let keyData = Data(keyBytes)
        print("BCRYPT\tKey = \(Matrix.Base64.padded(keyData))")
        
        return keyData
    }
}

/*
struct SecretStoragePasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        SecretStoragePasswordScreen()
    }
}
*/
