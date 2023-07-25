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
                Text("Connecting as \(creds.userId.description)")
                ProgressView()
                    .onAppear {
                        _ = Task {
                            try await store.connect(creds: creds)
                        }
                    }
            }
            
        case .signingUp(let signupSession):
            SignupScreen(session: signupSession, store: store)
        
        case .settingUp(let setupSession):
            SetupScreen(session: setupSession, store: store)
            
        case .loggingIn(let loginSession):
            LoginScreen(session: loginSession, store: store)

        case .online(let circlesSession):
            CirclesTabbedInterface(store: store, session: circlesSession)
                .environmentObject(circlesSession.galleries)
                //.environmentObject(circlesSession)
            
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
