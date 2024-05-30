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
            
        case .startingUp:
            ProgressView("Loading Circles...")
                .onAppear {
                    print("ContentView: Starting up")
                    Task {
                        try await store.lookForCreds()
                        print("ContentView: Back from lookForCreds()")
                    }
                }
            
        case .needCreds:
            WelcomeScreen(store: store)
            
        case .signingUp(let signupSession):
            SignupScreen(session: signupSession, store: store)
                .environmentObject(store.appStore)
        
        case .signedUp(let creds, let key):
            SignupFinishedView(creds: creds, key: key, store: store)
            
        case .loggingInUIA(let uiaLoginSession, let filter):
            UiaLoginScreen(session: uiaLoginSession, store: store, filter: filter)
            
        case .loggingInNonUIA(let legacyLoginSession):
            LegacyLoginScreen(session: legacyLoginSession, store: store)
            
        case .haveCreds(let creds, let key, let token):
            VStack {
                Spacer()
                
                Text("Connecting as \(creds.userId.description)")
                ProgressView()
                    .onAppear {
                        _ = Task {
                            do {
                                try await store.connect(creds: creds, s4Key: key, token: token)
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
            

        case .needSecretStorage(let matrix):
            SecretStorageCreationScreen(store: store, matrix: matrix)
            
        case .needSecretStorageKey(let matrix, let keyId, let keyDescription):
            SecretStoragePasswordScreen(store: store, matrix: matrix, keyId: keyId, description: keyDescription)
            
        case .haveSecretStorageAndKey(let matrix):
            ProgressView("Checking cross signing")
                .onAppear {
                    Task {
                        try await store.ensureCrossSigning()
                    }
                }
            
        case .haveCrossSigning(let matrix):
            ProgressView("Checking key backup")
                .onAppear {
                    Task {
                        try await store.ensureKeyBackup()
                    }
                }
            
        case .haveKeyBackup(let matrix):
            ProgressView("Checking space hierarchy")
                .onAppear {
                    Task {
                        try await store.checkForSpaceHierarchy()
                    }
                }
            
        case .needSpaceHierarchy(let matrix):
            SetupScreen(store: store, matrix: matrix)

        case .haveSpaceHierarchy(let matrix, let config):
            ProgressView("Loading Circles")
                .onAppear {
                    Task {
                        try await store.goOnline()
                    }
                }
            
        case .online(let circlesSession):
            CirclesTabbedInterface(store: store, session: circlesSession, viewState: circlesSession.viewState)
                .environmentObject(circlesSession)
                .environmentObject(store.appStore)
            
        case .error(_):
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
