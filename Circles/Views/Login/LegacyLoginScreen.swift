//
//  LegacyLoginScreen.swift
//  Circles
//
//  Created by Charles Wright on 10/31/23.
//

import SwiftUI
import Matrix

struct LegacyLoginScreen: View {
    @ObservedObject var session: LegacyLoginSession
    @State var password: String = ""
    @State var showPassword = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Enter password for \(session.userId.stringValue)")
                .font(.title2)
                .fontWeight(.bold)
            
            SecureFieldWithEye(label: "Password", text: $password, showText: showPassword)
                .frame(width: 300, height: 40)
                        
            AsyncButton(action: {
                try await session.login(password: password)
            }) {
                Text("Log In")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            
            Spacer()

            Button(role: .destructive, action: {}) {
                Text("Cancel")
            }
        }
        .padding()
    }
}

