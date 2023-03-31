//
//  UiaBsspekeView.swift
//  Circles
//
//  Created by Charles Wright on 3/30/23.
//

import Foundation
import SwiftUI
import Matrix

struct BsspekeEnrollOprfForm: View {
    var session: UIAuthSession<Matrix.Credentials>
    @State var password: String = ""
    @State var repeatPassword: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Set Passphrase")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack {
                SecureField("correct horse battery staple", text: $password, prompt: Text("New passphrase"))
                    .frame(width: 300.0, height: 40.0)
                SecureField("correct horse battery staple", text: $repeatPassword, prompt: Text("Repeat passphrase"))
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    guard let username = session.storage["username"] as? String,
                          let domain = session.storage["domain"] as? String,
                          let userId = UserId("@\(username):\(domain)")
                    else {
                        print("ERROR:\tCouldn't find username and/or domain")
                        return
                    }
                    try await session.doBSSpekeEnrollOprfStage(userId: userId, password: password)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(password.isEmpty || password != repeatPassword)
            }
            Spacer()
            VStack {
                Label("Tip: Choosing a strong passphrase", systemImage: "lightbulb")
                    .font(.headline)
                    .padding()
                Text("It's easier to remember a strong passphrase if you use more than one word")
            }
            .padding()
            Spacer()
        }
        .padding()
    }
}
