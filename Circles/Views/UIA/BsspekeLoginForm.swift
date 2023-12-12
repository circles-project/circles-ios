//
//  BsspekeLoginForm.swift
//  Circles
//
//  Created by Charles Wright on 8/7/23.
//

import SwiftUI
import Matrix

struct BsspekeLoginForm: View {
    var session: any UIASession
    var stage: String

    @State var passphrase: String = ""
    @State var failed = false

    @ViewBuilder
    var oprfForm: some View {
        VStack {
            Spacer()
            
            Text("Enter your passphrase")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            VStack {
                SecureField("Passphrase", text: $passphrase, prompt: Text("Passphrase"))
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    print("Doing BS-SPEKE OPRF stage for UIA")
                    try await session.doBSSpekeLoginOprfStage(password: passphrase)
                }) {
                    Text("Submit")
                        .padding()
                        .frame(width: 300.0, height: 40.0)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .disabled(passphrase.isEmpty)
                .alert(isPresented: $failed) {
                    Alert(title: Text("Incorrect Passphrase"),
                          message: Text("Passphrase authentication failed. Please double-check your passphrase and try again."),
                          dismissButton: .default(Text("OK"),
                                                  action: {
                                                    self.passphrase = ""
                                                  })
                    )
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var verifyForm: some View {
        VStack {
            Spacer()
            ProgressView {
                Text("Verifying passphrase")
            }
            Spacer()
        }
        .onAppear {
            self.failed = false
            Task {
                do {
                    try await session.doBSSpekeLoginVerifyStage()
                } catch {
                    await MainActor.run {
                        self.failed = true
                    }
                }
            }
        }

    }

    var body: some View {
        if stage == AUTH_TYPE_LOGIN_BSSPEKE_VERIFY {
            verifyForm
        } else {
            oprfForm
        }
    }
}

/*
struct BsspekeLoginForm_Previews: PreviewProvider {
    static var previews: some View {
        BsspekeLoginForm()
    }
}
*/
