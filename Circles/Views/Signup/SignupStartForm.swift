//
//  SignupStartForm.swift
//  Circles
//
//  Created by Charles Wright on 9/8/21.
//

import SwiftUI
import StoreKit
import Matrix

struct SignupStartForm: View {
    @ObservedObject var session: SignupSession
    var state: UIAA.SessionState
    @State private var canNotRegisterFlow: Bool = false
    
    var body: some View {
        VStack {
            Color.clear
                .onAppear {
                    Task {
                        if let freeFlow = state.flows.first(where: { flow in
                            flow.stages.contains(AUTH_TYPE_FREE_SUBSCRIPTION) &&
                            !flow.stages.contains(AUTH_TYPE_GOOGLE_SUBSCRIPTION) &&
                            !flow.stages.contains(AUTH_TYPE_APPSTORE_SUBSCRIPTION)
                        }) {
                            await session.selectFlow(flow: freeFlow)
                        } else {
                            let appleFlow = state.flows.first(where: {
                                $0.stages.contains(AUTH_TYPE_APPSTORE_SUBSCRIPTION)
                            })
                            
                            if appleFlow != nil {
                                await session.selectFlow(flow: appleFlow!)
                            } else {
                                canNotRegisterFlow = true
                            }
                        }
                    }
                }
            VStack {
                Label("We apologize, but new accounts are not currently available on this server.  Please check back later.", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }.opacity(canNotRegisterFlow ? 1 : 0)
        }
    }
}

/*
struct SignupStartForm_Previews: PreviewProvider {
    static var previews: some View {
        SignupScreen()
    }
}
*/
