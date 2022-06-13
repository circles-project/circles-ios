//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  LoginScreen.swift
//  Circles for iOS
//
//  Created by Charles Wright on 10/30/20.
//

import SwiftUI
import StoreKit

struct LoginScreen: View {
    @ObservedObject var session: LoginSession
    @State var password = ""
    
    var body: some View {
        VStack {
            switch session.state {
            case .notConnected:
                ProgressView()
                Text("Connecting to server")
            case .connected(let authTypes, let errorMessage):
                if authTypes.contains("m.login.password") {
                    RandomizedCircles()
                        .clipped()
                        .frame(minWidth: 100,
                               idealWidth: 200,
                               maxWidth: 300,
                               minHeight: 100,
                               idealHeight: 200,
                               maxHeight: 300,
                               alignment: .center)
                    
                    Text("Logging in as \(session.username)")

                    SecureFieldWithEye(label: "Password", text: $password)
                        .disableAutocorrection(true)
                        .frame(width: 300.0, height: 40.0)
                    
                    AsyncButton(action: {
                        guard !password.isEmpty else {
                            return
                        }
                        do {
                            try await session.passwordLogin(password)
                        } catch {
                            
                        }
                    }) {
                        Text("Submit password")
                            .padding()
                            .frame(width: 300.0, height: 40.0)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    
                    if let errMsg = errorMessage {
                        Text("Error: \(errMsg)")
                            .foregroundColor(Color.red)
                            .padding()
                    }
                    
                    Spacer()
                    
                    AsyncButton(action: {
                        do {
                            try await session.store.disconnect()
                        } catch {
                            
                        }
                    }) {
                        Text("Cancel")
                            .padding()
                            .frame(width: 300.0, height: 40.0)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    
                    
                } else {
                    Text("Password login is not supported")
                }
                
            case .inProgress(let authType):
                Text("Login in progress: [\(authType)]")
            
            case .failed(let errorMsg):
                Text("Login failed: \(errorMsg)")
            
            case .succeeded(let creds, let password):
                Text("Login success!")
                ProgressView()
                    .onAppear {
                        let _ = Task {
                            try await session.store.connectNewDevice(creds: creds, password: password)
                        }
                    }
            /*
            default:
                Text("Something else")
            */
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
