//
//  AccountInfoForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import Matrix

struct AccountInfoForm: View {
    //var matrix: MatrixInterface
    //@Binding var authFlow: UIAA.Flow?
    var session: SignupSession
    
    //let stage: String
    @Binding var accountInfo: SignupAccountInfo

    //@Binding var displayName: String
    //@Binding var username: String
    //@Binding var password: String
    @State var repeatPassword: String = ""
    //@Binding var emailAddress: String
    //@Binding var userId: String?

    //@Binding var emailSid: String?
    @Binding var emailSessionInfo: SignupSession.LegacyEmailRequestTokenResponse?

    @State var pending = false

    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    var showPassword = false

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
                        Image(systemName: SystemImages.questionmarkCircle.rawValue)
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
                        Image(systemName: SystemImages.questionmarkCircle.rawValue)
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
                        Image(systemName: SystemImages.questionmarkCircle.rawValue)
                    }
                }
                .frame(width: 300.0, height: 40.0)

                HStack {
                    SecureFieldWithEye(password: $accountInfo.password,
                                       isNewPassword: true,
                                       placeholder: "New Passphrase")
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(width: 300.0, height: 40.0)
                    Spacer()
                    Button(action: {
                        //showHelpItem = .password
                        self.showAlert = true
                        self.alertTitle = "Passphrase"
                        self.alertMessage = helpTextForPassword
                    }) {
                        Image(systemName: SystemImages.questionmarkCircle.rawValue)
                    }
                }
                .frame(width: 300.0, height: 40.0)

                SecureFieldWithEye(password: $repeatPassword,
                                   isNewPassword: true,
                                   placeholder: "Repeat Passphrase")
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(width: 300.0, height: 40.0)
            }

            Spacer()

            AsyncButton(action: {
                if session.storage["username"] == nil {
                    do {
                        try await session.doUsernameStage(username: accountInfo.username)
                    } catch {
                        print("SIGNUP-AccountInfoForm:\tFailed to enroll username")
                        // FIXME: Also set the error message for the UI
                        self.showAlert = true
                        self.alertTitle = "Error: Username"
                        self.alertMessage = "Please choose a different username."
                        return
                    }
                }
                
                if session.storage["password"] == nil {
                    do {
                        try await session.doPasswordEnrollStage(newPassword: accountInfo.password)
                    } catch {
                        print("SIGNUP-AccountInfoForm:\tFailed to set password")
                        // FIXME: Also set the error message for the UI
                        self.showAlert = true
                        self.alertTitle = "Error: Password"
                        self.alertMessage = "Please choose a different password."
                        return
                    }
                }
                
                do {
                    self.emailSessionInfo = try await session.doLegacyEmailRequestToken(address: accountInfo.emailAddress)
                } catch {
                    print("SIGNUP-AccountInfoForm:\tCouldn't send validation email")
                    // FIXME: Also set the error message for the UI
                    self.showAlert = true
                    self.alertTitle = "Error: Email"
                    self.alertMessage = "Please double-check that your email address is correct."
                    return
                }
            }) {
                Text("Submit")
            }
            .buttonStyle(BigRoundedButtonStyle())
            .disabled(accountInfo.username.isEmpty ||
                      accountInfo.password.isEmpty || accountInfo.password != repeatPassword ||
                      accountInfo.emailAddress.isEmpty)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .cancel(Text("OK"))
            )
        }
    }
}

/*
struct AccountInfoForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoForm()
    }
}
*/
