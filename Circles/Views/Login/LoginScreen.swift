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
            
        case .connected(let state):
            VStack {
                Text("Connected")
                Text("SessionID = \(state.session)")
            }
            
        default:
            VStack {
                
                Text("Login Screen")
                Text("beep boop")
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
