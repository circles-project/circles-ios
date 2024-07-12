//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ContentView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/16/20.
//

import SwiftUI
import Matrix

private struct ReusableLoadingView: View {
    let progressText: String
    let task: () async throws -> Void
    let cancelAction: (() async throws -> Void)?
    
    init(progressText: String, task: @escaping () async throws -> Void, cancelAction: (() async throws -> Void)? = nil) {
        self.progressText = progressText
        self.task = task
        self.cancelAction = cancelAction
    }
    
    var body: some View {
        ZStack {
            Color(.launch)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                
                BasicImage(name: SystemImages.launchCircleLogo.rawValue)
                    .frame(width: 215, height: 79)
                
                ProgressView(progressText)
                    .onAppear {
                        Task {
                            do {
                                try await task()
                            } catch {
                                print("Task failed: \(error)")
                            }
                        }
                    }
                    .background(Color(.launch))
                    .foregroundStyle(Color.white)
                
                Spacer()
                
                AsyncButton(role: .destructive, action: {
                    if let cancelAction = cancelAction {
                        try await cancelAction()
                    }
                }) {
                    Text("Cancel")
                }
                .foregroundStyle(cancelAction == nil ? Color(.launch) : Color.red)
            }
        }
    }
}

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
            ReusableLoadingView(progressText: "Loading Circles...") {
                try await store.lookForCreds()
                print("ContentView: Back from lookForCreds()")
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
            ReusableLoadingView(progressText: "Connecting as \(creds.userId.description)") {
                do {
                    try await store.connect(creds: creds, s4Key: key, token: token)
                } catch {
                    print("connect() failed -- disconnecting instead")
                    store.removeCredentials(for: creds.userId)
                    try await store.disconnect()
                }
            } cancelAction: {
                try await store.disconnect()
            }
            
        case .needSecretStorage(let matrix):
            SecretStorageCreationScreen(store: store, matrix: matrix)
            
        case .needSecretStorageKey(let matrix, let keyId, let keyDescription):
            SecretStoragePasswordScreen(store: store, matrix: matrix, keyId: keyId, description: keyDescription)
            
        case .haveSecretStorageAndKey(_): // (let matrix)
            ReusableLoadingView(progressText: "Checking cross signing") {
                try await store.ensureCrossSigning()
            }
            
        case .haveCrossSigning(_): // (let matrix)
            ReusableLoadingView(progressText: "Checking key backup") {
                try await store.ensureKeyBackup()
            }
            
        case .haveKeyBackup(_): // (let matrix)
            ReusableLoadingView(progressText: "Checking space hierarchy") {
                try await store.checkForSpaceHierarchy()
            }
            
        case .needSpaceHierarchy(let matrix):
            SetupScreen(store: store, matrix: matrix)

        case .haveSpaceHierarchy(_, _): // (let matrix, let config)
            ReusableLoadingView(progressText: "Loading Circles") {
                try await store.goOnline()
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
