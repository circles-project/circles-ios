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
                Text("Success!")
                Spacer()
            }
            .onAppear {
                if let creds = codableCreds as? Matrix.Credentials {
                    Task {
                        try await store.connect(creds: creds)
                    }
                }
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
