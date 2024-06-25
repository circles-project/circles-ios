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
            Text("Oh no! Something went wrong")
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
            ProgressView("Spinning up your Circles... Hang tight!")
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
                let textInPorgressView = DebugModel.shared.debugMode ? "" : "Yeah! We found you and are rushing to let you in"
                ProgressView(textInPorgressView)
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
                let text = DebugModel.shared.debugMode ? "Connecting as \(creds.userId.description)" : ""
                Text(text)
                
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
            let text = DebugModel.shared.debugMode ? "Checking cross signing" : "Checking your security connections"
            ProgressView(text)
                .onAppear {
                    Task {
                        try await store.ensureCrossSigning()
                    }
                }
            
        case .haveCrossSigning(let matrix):
            let text = DebugModel.shared.debugMode ? "Checking key backup" : "Ensuring your keys are safe"
            ProgressView(text)
                .onAppear {
                    Task {
                        try await store.ensureKeyBackup()
                    }
                }
            
        case .haveKeyBackup(let matrix):
            let text = DebugModel.shared.debugMode ? "Checking space hierarchy" : "Organizing your spaces"
            ProgressView(text)
                .onAppear {
                    Task {
                        try await store.checkForSpaceHierarchy()
                    }
                }
            
        case .needSpaceHierarchy(let matrix):
            SetupScreen(store: store, matrix: matrix)

        case .haveSpaceHierarchy(let matrix, let config):
            let text = DebugModel.shared.debugMode ? "Loading Circles" : "Just a moment, almost there—we promise!"
            ProgressView(text)
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
