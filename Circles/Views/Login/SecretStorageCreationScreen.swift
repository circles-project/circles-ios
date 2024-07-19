//
//  SecretStorageCreationScreen.swift
//  Circles
//
//  Created by Charles Wright on 1/29/24.
//

import SwiftUI
import Matrix
import IDZSwiftCommonCrypto

struct SecretStorageCreationScreen: View {
    var store: CirclesStore
    @ObservedObject var matrix: Matrix.Session
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("This account does not appear to be set up for secure storage on the server.")
                .font(.title2)
                .padding()
            
            Spacer()
            
            Label("Tip: If this is a new account, tap \"Set up secure storage\" to get started.", systemImage: "lightbulb.fill")
            
            AsyncButton(action: {
                guard let _ = matrix.secretStore // let secretStore
                else {
                    print("No secret storage!")
                    return
                }
                let bytes = try Random.generateBytes(byteCount: 32)
                let data = Data(bytes)
                let keyId = try Random.generateBytes(byteCount: 16)
                    .map {
                        String(format: "%02hhx", $0)
                    }
                    .joined()
                let description = try Matrix.SecretStore.generateKeyDescription(key: data, keyId: keyId)
                let key = Matrix.SecretStorageKey(key: data, keyId: keyId, description: description)
                print("Initializing secret storage with key id \(keyId)")
                try await store.initSecretStorage(key: key)
                print("Done initializing secret storage")
            }) {
                Text("Set up secure storage")
                    .padding()
            }
            .padding()
            
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
