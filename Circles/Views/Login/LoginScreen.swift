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

struct LoginScreen: View {
    @ObservedObject var session: LoginSession
    var store: CirclesStore
    @State var password = ""
    
    var body: some View {

        switch session.state {
            
        case .notConnected:
            VStack {
                ProgressView()
                Text("Connecting to server")
                    .onAppear {
                        let _ = Task {
                            try await session.connect()
                        }
                    }
            }
            
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
            
        case .finished(let codableCreds):
            VStack {
                Spacer()
                if let creds = codableCreds as? Matrix.Credentials {
                    Text("Success!")
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

}

/*
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(matrix: KSStore())
    }
}
*/
