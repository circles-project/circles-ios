//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoginScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/30/20.
//

import SwiftUI
import StoreKit
import Matrix

struct UiaLoginScreen: View {
    @ObservedObject var session: UiaLoginSession
    var store: CirclesStore
    @State var password = ""
    
    
    @ViewBuilder
    var currentStatusView: some View {

        switch session.state {
            
        case .notConnected:
            VStack(spacing: 50) {
                ProgressView()
                    .scaleEffect(3)
                Text("Connecting to server")
                    .onAppear {
                        let _ = Task {
                            try await session.connect()
                        }
                    }
            }
            
        case .failed(let error):
            VStack(spacing: 25) {
                Label("Error", systemImage: "exclamationmark.triangle")
                    .font(.title)
                    .fontWeight(.bold)
                Text("The server rejected our request to log in.")
                Text("Please double-check your user id and then try again.")
            }
            .padding()
            
        case .connected(let uiaaState):
            VStack {
                ProgressView()
            }
            .onAppear {
                if uiaaState.flows.count == 1,
                   let flow = uiaaState.flows.first
                {
                    Task {
                        await session.selectFlow(flow: flow)
                    }
                } else {
                    if let flow = uiaaState.flows.first(where: {
                        $0.stages.contains(AUTH_TYPE_LOGIN_BSSPEKE_OPRF) && $0.stages.contains(AUTH_TYPE_LOGIN_BSSPEKE_VERIFY)
                    }) {
                        Task {
                            await session.selectFlow(flow: flow)
                        }
                    }
                }
            }
            
        case .inProgress(let uiaaState, let stages):
            UiaInProgressView(session: session, state: uiaaState, stages: stages)
            
        case .finished(let data):
            VStack {
                Spacer()
                
                if let creds = try? JSONDecoder().decode(Matrix.Credentials.self, from: data) {
                    Text("Success!")
                    ProgressView()
                        /*
                        .onAppear {
                            /*
                            // Moving this stuff into the callback that we provide when we create the session in the `CirclesStore`
                            var keys = [String: Data]()
                            if let bsspeke = session.getBSSpekeClient() {
                                let ssssKey = bsspeke.generateHashedKey(label: "matrix_ssss")
                                keys["0x1234"] = Data(ssssKey)
                            }
                            */
                            print("LoginScreen:\tLogin success - Telling the Store to connect()")
                            Task {
                                try await store.connect(creds: creds)
                            }
                        }
                        */
                } else {
                    Text("Login success, but there was a problem...")
                }
                Spacer()
            }
            
        default:
            VStack {
                Spacer()
                Text("Something went wrong")
                Spacer()
            }
        }
  
    }

    var body: some View {
        VStack {
            Spacer()

            currentStatusView
            
            Spacer()
            
            AsyncButton(role: .destructive, action: {
                //try await session.cancel()
                try await store.disconnect()
            }) {
                Text("Cancel Login")
            }
            .buttonStyle(.bordered)
        }
    }
}

/*
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(matrix: KSStore())
    }
}
*/
