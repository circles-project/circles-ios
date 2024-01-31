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
            Text("This account does not appear to be set up for secure storage on the server.")
            
            Label("Tip: If this is a new account, tap \"Set up secure storage\" to get started.", systemImage: "lightbulb.fill")
            
            Button(action: {}) {
                Text("Set up secure storage")
            }
            
            Button(action: {}) {
                Text("Cancel")
            }
        }
    }
}
