//
//  EmailEnrollForm.swift
//  Circles
//
//  Created by Charles Wright on 3/31/23.
//

import Foundation
import SwiftUI
import Matrix

struct EmailEnrollRequestTokenForm: View {
    var session: UIAuthSession<Matrix.Credentials>
    @Binding var secret: String
    @State var address = ""
    
    var addressIsValid: Bool {
        // https://stackoverflow.com/questions/201323/how-can-i-validate-an-email-address-using-a-regular-expression
        let regex = #/(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/#
        guard let match = try? regex.wholeMatch(in: address)
        else {
            return false
        }
        return true
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Verify your email address")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("We will send a short 6-digit code to your email address to verify your identity")
            }
            VStack {
                TextField("you@example.com", text: $address, prompt: Text("Email address"))
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    if let secret = try await session.doEmailRequestTokenStage(email: address) {
                        self.secret = secret
                    }
                }) {
                    Text("Send Code")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(!addressIsValid)
            }
            Spacer()
            VStack {
                Label("Protecting Your Privacy", systemImage: "envelope.badge.shield.half.filled")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("We will never sell your information or use it for advertising.  See our [Privacy Policy](https://circu.li/privacy.html) for more information.")
                    .padding()
            }
            Spacer()
        }
        .padding()
    }
}
