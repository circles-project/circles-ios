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
    var filter: Matrix.AuthFlowFilter
    
    @AppStorage("previousUserIds") var previousUserIds: [UserId] = []
    
    @State var password = ""
    
    @State var flowErrorMessage: String?
    
    
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
                if let msg = self.flowErrorMessage {
                    Label("Error!", systemImage: "exclamationmark.triangle")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(msg)")
                } else {
                    ProgressView()
                    Text("Loading...")
                }
            }
            .task {
                
                if let flow = uiaaState.flows.first(where: self.filter) {
                    await session.selectFlow(flow: flow)
                } else {
                    await MainActor.run {
                        self.flowErrorMessage = "No compatible login flows"
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
                        .onAppear {
                            // Add our user id to the list, for easy login in the future
                            let allUserIds: Set<UserId> = Set(previousUserIds).union([creds.userId])
                            previousUserIds = allUserIds.sorted { $0.stringValue < $1.stringValue }
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
