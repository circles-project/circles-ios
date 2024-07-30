//
//  LegacyLoginScreen.swift
//  Circles
//
//  Created by Charles Wright on 10/31/23.
//

import SwiftUI
import Matrix
import KeychainAccess

struct LegacyLoginScreen: View {
    @ObservedObject var session: LegacyLoginSession
    var store: CirclesStore

    @AppStorage("previousUserIds") var previousUserIds: [UserId] = []
    
    @State var password: String = ""
    @State var showPassword = false
    
    var body: some View {
        VStack {
            if DebugModel.shared.debugMode {
                Text("m.login.password")
                    .foregroundColor(.red)
            }
            Spacer()
            
            Text("Enter password for \(session.userId.stringValue)")
                .font(.title2)
                .fontWeight(.bold)
            SecureFieldWithEye(password: $password,
                               isNewPassword: false,
                               placeholder: "Password")
                .textContentType(.password)
                .frame(width: 300, height: 40)
                .onAppear {
                    // Attempt to load the saved password that Matrix.swift should have saved in our Keychain
                    let keychain = Keychain(server: "https://\(session.userId.domain)", protocolType: .https)
                    keychain.getSharedPassword(session.userId.stringValue) { (passwd, error) in
                        if self.password.isEmpty,
                           let savedPassword = passwd
                        {
                            self.password = savedPassword
                        }
                    }
                }
                        
            AsyncButton(action: {
                try await session.login(password: password)
                
                // Add our user id to the list, for easy login in the future
                let allUserIds: Set<UserId> = Set(previousUserIds).union([session.userId])
                previousUserIds = allUserIds.sorted { $0.stringValue < $1.stringValue }
                
                // Save our password in the Keychain
                let keychain = Keychain(server: "https://\(session.userId.domain)", protocolType: .https)
                keychain.setSharedPassword(password, account: session.userId.stringValue)
            }) {
                Text("Log In")
            }
            .buttonStyle(BigRoundedButtonStyle())
            
            Spacer()

            AsyncButton(role: .destructive, action: {
                try await store.disconnect()
            }) {
                Text("Cancel")
            }
        }
        .padding()
    }
}

