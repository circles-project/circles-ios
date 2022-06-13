//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ContentView.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/16/20.
//

import SwiftUI
import MatrixSDK

struct ContentView: View {
    @ObservedObject var store: CirclesStore
    
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
                Text("Connecting as \(creds.userId)")
                ProgressView()
                    .onAppear {
                        _ = Task {
                            try await store.connect(creds: creds)
                        }
                    }
            }
            
        case .signingUp(let signupSession):
            SignupScreen(session: signupSession, store: store)
        
        case .settingUp(let creds):
            SetupScreen(creds: creds, store: store)
            
        case .loggingIn(let loginSession):
            LoginScreen(session: loginSession)

        case .online(let legacyStore):
            LoggedinScreen(store: store, legacyStore: legacyStore)

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
