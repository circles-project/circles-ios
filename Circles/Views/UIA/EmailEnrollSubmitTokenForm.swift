//
//  EmailEnrollSubmitTokenForm.swift
//  Circles
//
//  Created by Charles Wright on 3/31/23.
//

import Foundation
import SwiftUI
import Matrix

struct EmailEnrollSubmitTokenForm: View {
    var session: any UIASession
    var secret: String

    @State var token = ""
    
    var tokenIsValid: Bool {
        token.count == 6 && Int(token) != nil
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Enter the 6-digit code that you received in your email")
            }
            Spacer()
            VStack {
                TextField("123456", text: $token, prompt: Text("6-Digit Code"))
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    try await session.doEmailEnrollSubmitTokenStage(token: token, secret: secret)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(!tokenIsValid)
            }
            Spacer()
        }
    }
}
