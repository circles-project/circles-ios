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
    @State var flowErrorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var backButton: some View {
        Button(role: .destructive, action: {
            Task {
                try await self.store.disconnect()
            }
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(SystemImages.iconFilledArrowBack.rawValue)
                .padding(5)
                .frame(width: 40.0, height: 40.0)
        }
        .background(Color.white)
        .clipShape(Circle())
        .padding(.leading, 21)
        .padding(.top, 65)
    }
    
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
            
        case .failed(_): // let error
            VStack(spacing: 25) {
                Label("Error", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                Text("The server rejected our request to log in.")
                Text("Please double-check your user id and then try again.")
            }
            .padding()
            
        case .connected(let uiaaState):
            VStack {
                if let msg = self.flowErrorMessage {
                    Label("Error!", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
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
                    ProgressView()
                        .onAppear {
                            // Add our user id to the list, for easy login in the future
                            let allUserIds: Set<UserId> = Set(previousUserIds).union([creds.userId])
                            previousUserIds = allUserIds.sorted { $0.stringValue < $1.stringValue }
                        }
                    Text("Success!")
                } else {
                    Text("Login success, but there was a problem...")
                }
                Spacer()
            }
            
        default:
            VStack {
                Spacer()
                Text("Oh, no! Something went wrong")
                Spacer()
            }
        }
    }

    var body: some View {
        ZStack {
            Color.greyCool200
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                
                Spacer()
                
                currentStatusView
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
