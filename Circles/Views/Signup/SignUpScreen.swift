//  Copyright 2021 Kombucha Digital Privacy Systems LLC
//
//  SignupScreen.swift
//  Circles
//
//  Created by Charles Wright on 6/28/21.
//

import SwiftUI
import Matrix

struct SignupAccountInfo {
    var displayName: String = ""
    var username: String = ""
    var password: String = ""
    var emailAddress: String = ""
    var userId: String = ""
}

struct SignupScreen: View {
    //@EnvironmentObject var appStore: AppStoreInterface

    //var matrix: MatrixInterface
    //@Binding var uiaaState: UiaaSessionState?
    @ObservedObject var session: SignupSession
    var store: CirclesStore

    //@State var selectedFlow: UIAA.Flow?
    //@State var creds: Matrix.Credentials?
    //@State var emailSessionId: String?
    //@State var emailSessionInfo: SignupSession.LegacyEmailRequestTokenResponse?

    @State var accountInfo = SignupAccountInfo()
    
    var cancelButton: some View {
        AsyncButton(action: {
            //self.selectedScreen = .login
            do {
                try await self.store.disconnect()
            } catch {
                
            }
        }) {
            Text("Cancel")
                .padding()
                .frame(width: 300.0, height: 40.0)
                .foregroundColor(.red)
                .cornerRadius(10)
        }
    }
    
    var notConnectedView: some View {
        VStack {
            Spacer()
            ProgressView()
                .onAppear {
                    let _ = Task {
                        try await session.connect()
                    }
                }
            Text("Connecting to server")
            Spacer()
        }
    }
    
    var body: some View {
        VStack {
            switch session.state {
            case .notConnected:
                notConnectedView
                
            case .failed(let error):
                Text("Signup failed")
                
            case .canceled:
                Text("Signup canceled")

            case .connected(let uiaaState):
                SignupStartForm(session: session, store: store, state: uiaaState)

            case .inProgress(let uiaaState, let stages):
                UiaInProgressView(session: session, state: uiaaState, stages: stages)
                
            case .finished(let data):
                let decoder = JSONDecoder()
                
                if let creds = try? decoder.decode(Matrix.Credentials.self, from: data) {
                    SignupFinishedView(store: store, creds: creds)
                } else {
                    Text("There was a problem")
                }
            }
        }
        Spacer()
        cancelButton
    }

}

/*
struct SignupScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
