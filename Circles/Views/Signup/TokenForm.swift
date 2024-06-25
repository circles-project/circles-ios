//
//  TokenForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import Matrix

struct TokenForm: View {
    let tokenType: String
    //var matrix: MatrixInterface
    var session: SignupSession

    @State var signupToken: String = ""

    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""

    let helpTextForToken = """
    In order to sign up for the service, every new user must present a valid registration token.

    If you found out about the app from a friend or from a posting online, you should be able to get a signup token from the same source.
    """

    let helpTextForTokenFailed = """
    Failed to validate token
    """

    //let stage = LOGIN_STAGE_SIGNUP_TOKEN

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .validateToken

            Spacer()

            Text("Validate your token")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                TextField("abcd-efgh-1234-5678", text: $signupToken)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Spacer()
                Button(action: {
                    self.showAlert = true
                    self.alertTitle = "Signup Token"
                    self.alertMessage = helpTextForToken
                }) {
                    Image(systemName: SystemImages.questionmarkCircle.rawValue)
                }
            }
            .frame(width: 300.0, height: 40.0)

            AsyncButton(action: {
                if self.signupToken.isEmpty {
                    return
                }
                
                do {
                    try await session.doTokenRegistrationStage(token: self.signupToken)
                } catch {
                    // Well crap, I guess it didn't work
                    self.alertTitle = "Token validation failed"
                    self.alertMessage = helpTextForTokenFailed
                    self.showAlert = true
                }

            }) {
                Text("Validate Token")
            }
            .buttonStyle(BigBlueButtonStyle())
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .cancel(Text("OK"))
                )
            }

            Spacer()

        }
    }
}

/*
struct TokenStage_Previews: PreviewProvider {
    static var previews: some View {
        TokenStage()
    }
}
*/
