//
//  SignupFinishedView.swift
//  Circles
//
//  Created by Charles Wright on 8/1/23.
//

import SwiftUI
import Matrix

struct SignupFinishedView: View {
    var creds: Matrix.Credentials
    var key: Matrix.SecretStorageKey?
    var store: CirclesStore

    var body: some View {
        ZStack {
            Color.greyCool200
            
            VStack {
                CirclesLogoView()
                    .frame(minWidth: 100,
                           idealWidth: 150,
                           maxWidth: 200,
                           minHeight: 100,
                           idealHeight: 150,
                           maxHeight: 200,
                           alignment: .center)
                
                Text("Successfully signed up!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack {
                    Text("Your new user ID is:")
                    Text(creds.userId.stringValue)
                        .padding(.leading)
                        .padding(.top)
                }
                .padding(.vertical, 20)
                
                Text("Your user ID works like a username or an email address. Friends will need your user ID in order to invite you to follow them.")
                
                Spacer()
                
                AsyncButton(action: {
                    do {
                        try await store.connect(creds: creds, s4Key: key)
                    } catch {
                        print("Failed to connect with creds for user \(creds.userId)")
                    }
                }) {
                    Text("Next: Set up your account")
                }
                .buttonStyle(BigRoundedButtonStyle())
            }
            .padding()
        }
        .background(Color.greyCool200)
    }
}

