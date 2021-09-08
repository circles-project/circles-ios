//
//  ValidateEmailForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI

struct ValidateEmailForm: View {
    var matrix: MatrixInterface

    @State var emailToken = ""
    @Binding var emailSid: String

    @Binding var username: String
    @Binding var password: String
    @Binding var userId: String?
    @Binding var displayName: String

    @State var pending = false

    @Binding var showAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String

    let helpTextForEmailCode = """
    We sent a 6-digit code to your email address to validate your account.

    Enter the code here to verify that this address belongs to you.
    """

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .validateEmail

            Spacer()

            Text("Validate your email address")
                .font(.headline)

            HStack {
                TextField("123456", text: $emailToken)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    //.frame(width: 300.0, height: 40.0)
                Spacer()
                Button(action: {
                    self.showAlert = true
                    self.alertTitle = "Email code"
                    self.alertMessage = helpTextForEmailCode
                }) {
                    Image(systemName: "questionmark.circle")
                }
            }
            .frame(width: 300.0, height: 40.0)

            Button(action: {
                guard !emailToken.isEmpty else {
                    return
                }
                self.pending = true
                // Call out to the server to validate our email address
                matrix.signupValidateEmailAddress(sid: self.emailSid, token: self.emailToken) { response1 in
                    if response1.isSuccess {
                        // Next we need to do the UIAA stage for the email identity
                        matrix.signupDoEmailStage(username: self.username, password: self.password, sid: self.emailSid) { response2 in
                            switch response2 {
                            case .success(let maybeCreds):
                                print("Email UIAA stage success!")
                                if let creds = maybeCreds {
                                    print("Creds: user id = \(creds.userId!)")
                                    print("Creds: device id = \(creds.deviceId!)")
                                    print("Creds: access token = \(creds.accessToken!)")

                                    self.userId = creds.userId!

                                    if self.displayName.isEmpty {
                                        self.pending = false
                                        //self.stage = next[currentStage]!
                                    } else {
                                        matrix.setDisplayName(name: self.displayName) { response in
                                            if response.isSuccess {
                                                //self.stage = next[currentStage]!
                                            }
                                            self.pending = false
                                        }
                                    }
                                } else {
                                    self.pending = false
                                    print("Email UIAA stage succeeded, but registration is not yet complete")
                                }
                            case .failure(let err):
                                self.pending = false
                                print("Email UIAA stage failed")
                            }
                        }
                    } else {
                        self.pending = false
                        print("Email code validation failed")
                    }
                }
            }) {
                Text("Verify Code from Email")
            }
            .disabled(pending)
            .padding()
            .frame(width: 300.0, height: 40.0)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(10)

            Spacer()

            Button(action: {
                //self.stage = .getUsernameAndPassword
            }) {
                Text("Go Back")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.red)
                    //.background(Color.accentColor)
                    .cornerRadius(10)
            }

        }
    }
}

/*
struct ValidateEmailView_Previews: PreviewProvider {
    static var previews: some View {
        ValidateEmailView()
    }
}
*/
