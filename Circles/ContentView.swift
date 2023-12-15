//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ContentView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/16/20.
//

import SwiftUI
import Matrix

struct ContentView: View {
    @ObservedObject var store: CirclesStore
    @State var showUIA = false
    
    var errorView: some View {
        VStack {
            Text("Something went wrong")
            AsyncButton(action: {
                do {
                    try await self.store.disconnect()
                } catch {
                    
                }
            }) {
                Text("Logout and try again...")
            }
        }
    }

    var body: some View {

        switch(store.state) {
            
        case .nothing:
            WelcomeScreen(store: store)
            
        case .haveCreds(let creds):
            VStack {
                Spacer()
                
                Text("Connecting as \(creds.userId.description)")
                ProgressView()
                    .onAppear {
                        _ = Task {
                            do {
                                try await store.connect(creds: creds)
                            } catch {
                                print("connect() failed -- disconnecting instead")
                                store.removeCredentials(for: creds.userId)
                                try await store.disconnect()
                            }
                        }
                    }
                
                Spacer()
                
                AsyncButton(role: .destructive, action: {
                    try await store.disconnect()
                }) {
                    Text("Cancel")
                }
            }
            
        case .signingUp(let signupSession):
            SignupScreen(session: signupSession, store: store)
                .environmentObject(store.appStore)
        
        case .settingUp(let setupSession):
            SetupScreen(session: setupSession, store: store)
            
        case .loggingInUIA(let uiaLoginSession):
            UiaLoginScreen(session: uiaLoginSession, store: store)
            
        case .loggingInNonUIA(let legacyLoginSession):
            LegacyLoginScreen(session: legacyLoginSession)
            
        case .needSSKey(let matrix, let keyId, let keyDescription):
            SecretStoragePasswordScreen(store: store, matrix: matrix, keyId: keyId, description: keyDescription)

        case .online(let circlesSession):
            CirclesTabbedInterface(store: store, session: circlesSession)
                .environmentObject(circlesSession)
                .environmentObject(store.appStore)
            
        default:
            errorView
        }
    }

}


/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: CirclesStore())
    }
}
*/
