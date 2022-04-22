//
//  AccountInfoForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI

#if false

struct AccountInfoForm: View {
    var matrix: MatrixInterface
    @Binding var authFlow: UIAA.Flow?
    let stage: String
    @Binding var accountInfo: SignupAccountInfo

    //@Binding var displayName: String
    //@Binding var username: String
    //@Binding var password: String
    @State var repeatPassword: String = ""
    //@Binding var emailAddress: String
    //@Binding var userId: String?

    @Binding var emailSid: String?

    @State var pending = false

    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""

    let helpTextForName = "Your name as you would like it to appear to others"

    let helpTextForEmailAddress = """
    Must be a currently valid and active address.

    Don't worry -- we will only use this address for security and other alerts about your account.  We don't send spam, and we don't sell your address.
    """

    let helpTextForUsername = """
    Your username is how other users on the service will identify you.

    The username must consist of at least 8 characters, including at least two letters [a-z].

    If you like, you can also use the numeric digits [0-9] and/or a few special characters like the dash, underscore, and period or "dot".
    """

    let helpTextForPassword = """
    Please choose a passphrase that is hard to guess.

    You should use at least one numeral and one punctuation character.

    Combine at least 3 or 4 words to make an even stronger passphrase.
    """


    var body: some View {
        VStack {
            //let currentStage: SignupStage = .getUsernameAndPassword

            Text("Set up username and password")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            VStack {
                Text("Your name and email address")
                    .font(.headline)
                    .padding(.top)

                HStack {
                    TextField("Your Name", text: $accountInfo.displayName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                    Spacer()
                    Button(action: {
                        self.showAlert = true
                        self.alertTitle = "Name"
                        self.alertMessage = helpTextForName
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                .frame(width: 300.0, height: 40.0)

                HStack {
                    TextField("you@example.com", text: $accountInfo.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Spacer()
                    Button(action: {
                        self.showAlert = true
                        self.alertTitle = "Email Address"
                        self.alertMessage = helpTextForEmailAddress
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                .frame(width: 300.0, height: 40.0)
            }

            Spacer()

            VStack {
                Text("Your new account")
                    .font(.headline)
                    .padding(.top)

                HStack {
                    TextField("New Username", text: $accountInfo.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Spacer()
                    Button(action: {
                        //showHelpItem = .username
                        self.showAlert = true
                        self.alertTitle = "Username"
                        self.alertMessage = helpTextForUsername
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                .frame(width: 300.0, height: 40.0)

                HStack {
                    SecureField("New Passphrase", text: $accountInfo.password)
                        .textContentType(.newPassword)
                    Spacer()
                    Button(action: {
                        //showHelpItem = .password
                        self.showAlert = true
                        self.alertTitle = "Passphrase"
                        self.alertMessage = helpTextForPassword
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                .frame(width: 300.0, height: 40.0)

                SecureField("Repeat Passphrase", text: $repeatPassword)
                    .textContentType(.newPassword)
                    .frame(width: 300.0, height: 40.0)
            }

            Spacer()

            Button(action: {
                guard !accountInfo.password.isEmpty,
                      accountInfo.password == repeatPassword,
                      !accountInfo.username.isEmpty else {
                    return
                }
                // Call out to the server to send the verification mail
                self.pending = true
                matrix.signupRequestEmailToken(email: accountInfo.emailAddress) { response in
                    if case let .success(sid) = response {
                        // Setting the email session ID will send us to the next screen in the UI, since that's the next piece that we're missing.
                        self.emailSid = sid
                    } else {
                        // :( Couldn't validate email
                        print(":( Couldn't send validation email")
                    }
                    self.pending = false
                }
            }) {
                Text("Submit")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(accountInfo.password.isEmpty || accountInfo.password != repeatPassword || pending)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .cancel(Text("OK"))
            )
        }
    }
}
#endif

/*
struct AccountInfoForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoForm()
    }
}
*/
