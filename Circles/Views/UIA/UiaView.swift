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
    @State private var errorMessage = ""
    
    var showErrorMessageView: some View {
        VStack {
            if errorMessage != "" {
                ToastView(titleMessage: errorMessage)
                Text("")
                    .onAppear {
                        errorMessage = ""
                    }
            }
        }
    }
    
    var body: some View {
        VStack {
            showErrorMessageView
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            // cvw: Based on the SignupScreen
            switch uia.state {
            case .notConnected:
                AsyncButton(action: {
                    do {
                        try await uia.connect()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }) {
                    Text("Tap to Authenticate")
                }
                
            case .failed(_):
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
                
            case .finished(_):
                Text("Success!")
                    .onAppear {
                        _ = Task {
                            do {
                                try await session.cancelUIA()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AsyncButton(role: .destructive, action: {
                do {
                    try await session.cancelUIA()
                } catch {
                    errorMessage = error.localizedDescription
                }
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
