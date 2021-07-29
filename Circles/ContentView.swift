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
    @ObservedObject var store: KSStore

    var body: some View {

        switch(store.state) {

        case .blockedOnTerms(let terms):
            TermsScreen(store: store, terms: terms)

        case .normal(let sessionState):

            switch(sessionState) {

            case MXSessionStateInitialised,
                 MXSessionStateSyncInProgress:
                VStack {
                    ProgressView("Syncing latest data from the server")
                }

            case MXSessionStateRunning,
                 MXSessionStateBackgroundSyncInProgress:
                LoggedinScreen(store: self.store)

            case MXSessionStateClosed,
                 MXSessionStateUnknownToken,
                 MXSessionStateSoftLogout:
                LoggedOutScreen(store: self.store)

            case MXSessionStateHomeserverNotReachable:
                // FIXME This should be some sort of pop-up that then sends you back to the login screen
                // FIXME Alternatively, if we have a (seemingly) valid access token, we could allow the user to browse the data that we already have locally, in some sort of "offline" mode
                VStack {
                    ProgressView("Reconnecting to server \(store.homeserver?.host ?? "")")
                }
            case MXSessionStatePauseRequested:
                VStack {
                    ProgressView("Logging out...")
                }
            case MXSessionStatePaused:
                VStack {
                    Text("Logout successful")

                    Button(action: {
                        self.store.close()
                    }) {
                        Text("Return to login screen")
                            .padding()
                            .frame(width: 300.0, height: 40.0)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                }

            default:
                VStack {
                    Text("Something went wrong")
                    Button(action: {self.store.pause()}) {
                        Text("Logout and try again...")
                    }
                }
            }

        default:
            Text("Uh, I dunno...")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: KSStore())
    }
}
