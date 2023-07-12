//
//  SecuritySettingsView.swift
//  Circles
//
//  Created by Charles Wright on 7/5/23.
//

import SwiftUI
import Matrix

struct SecuritySettingsView: View {
    var session: Matrix.Session
    
    @ViewBuilder
    var passwordButton: some View {
        AsyncButton(action: {
            try await session.setBsSpekePassword() { (uiaSession, data) in
                
                if let store = session.secretStore {
                    guard let bsspeke = uiaSession.getBSSpekeClient()
                    else {
                        print("Error: Failed to get BS-SPEKE client after changing password")
                        return
                    }
                    
                    let key = Data(bsspeke.generateHashedKey(label: MATRIX_SSSS_KEY_LABEL))
                    let keyId = try Matrix.SecretStore.computeKeyId(key: key)
                    
                    // Set the key as our new default key for Secret Storage - This automatically encrypts and saves the old key on the server
                    try await store.addNewDefaultKey(key: key, keyId: keyId)
                    
                    // Save the keys into our device Keychain, so they will be available to future Matrix sessions where we load creds and connect, without logging in
                    let keychain = Matrix.KeychainSecretStore(userId: session.creds.userId)
                    try await keychain.saveKey(key: key, keyId: keyId)
                }
                else {
                    print("No secret storage - Not computing new BS-SPEKE-based SSSS key")
                }
            }
        }) {
            //Text("Change Password")
            Label("Change Password", systemImage: "entry.lever.keypad")
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    var enrollEmailButton: some View {
        AsyncButton(action: {
            try await session.updateAuth(filter: { $0.stages.contains(AUTH_TYPE_ENROLL_EMAIL_SUBMIT_TOKEN)})
        }) {
            //Text("Change Password")
            Label("Change Email Address", systemImage: "envelope")
        }
        .buttonStyle(.plain)
    }
    
    var body: some View {
        //NavigationView {
        VStack {
            Form {
                Label("Login Sessions", systemImage: "iphone")

                passwordButton

                enrollEmailButton
            }
            .navigationTitle("Account Security")
        }
    }
}

/*
struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettingsView()
    }
}
*/
