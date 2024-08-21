//
//  UiaView.swift
//  Circles
//
//  Created by Charles Wright on 6/22/23.
//

import SwiftUI
import Matrix

struct UiaView: View {
    var session: CirclesApplicationSession
    //var matrix: Matrix.Session
    @ObservedObject var uia: UIAuthSession
    
    var body: some View {
        VStack {
            Text("Authentication Required")
                .font(
                    CustomFonts.nunito24
                        .bold()
                )
                .padding()
            
            Spacer()
            
            // cvw: Based on the SignupScreen
            switch uia.state {
            case .notConnected:
                AsyncButton(action: {
                    try await uia.connect()
                }) {
                    Text("Tap to Authenticate")
                }
                
            case .failed(_):  // let error
                Text("Authentication failed")
                
            case .canceled:
                Text("Authentication canceled")

            case .connected(let uiaaState):
                ProgressView()
                    .onAppear {
                        // Choose a flow
                        // FIXME: Just go with the first one for now
                        if let flow = uiaaState.flows.first {
                            _ = Task { await uia.selectFlow(flow: flow) }
                        }
                    }

            case .inProgress(let uiaaState, let stages):
                UiaInProgressView(session: uia, state: uiaaState, stages: stages)
                
            case .finished(_): // let data
                Text("Success!")
                    .onAppear {
                        _ = Task {
                            try await session.cancelUIA()
                        }
                    }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AsyncButton(role: .destructive, action: {
                try await session.cancelUIA()
            }) {
                Text("Cancel")
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}

/*
struct UiaView_Previews: PreviewProvider {
    static var previews: some View {
        UiaView()
    }
}
*/
