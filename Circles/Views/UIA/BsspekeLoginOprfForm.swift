//
//  BsspekeLoginOprfForm.swift
//  Circles
//
//  Created by Charles Wright on 4/3/23.
//

import Foundation
import SwiftUI
import Matrix

struct BsspekeLoginOprfForm: View {
    var session: UIASession
    
    @State var password: String = ""

    var body: some View {
        VStack {
            Spacer()
            Text("Enter your password")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            VStack {
                SecureField("Passphrase", text: $password, prompt: Text("Passphrase"))
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    try await session.doBSSpekeLoginOprfStage(password: password)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(password.isEmpty)
            }
            Spacer()
        }
    }
}
