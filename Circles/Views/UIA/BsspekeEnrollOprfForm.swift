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
    var session: UIAuthSession
    @State var passphrase: String = ""
    @State var repeatPassphrase: String = ""
    //@State var passwordStrength: Int = 0
    @State var score: Double = 0.0
    @State var color: Color = .red
    //@State var passwordStrengthColors: [Color] = []
    let checker = DBZxcvbn()
    
    let buttonWidth = UIScreen.main.bounds.width - 48
    let buttonHeight: CGFloat = 48.0

    #if DEBUG
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 2.0
    #else
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 3.0
    #endif
    
    enum Screen: String {
        case enterPassword
        case savePassword
    }
    @State var screen: Screen = .enterPassword
    //@State var showRepeat = false
    var showPassword = false
    
    private func getUserId() -> UserId? {
        if let userId = session.creds?.userId {
            return userId
        }
        
        if let userId = session.storage["userId"] as? UserId {
            return userId
        }
        
        if let username = session.storage["username"] as? String,
              let domain = session.storage["domain"] as? String,
              let userId = UserId("@\(username):\(domain)")
        {
            return userId
        }
        else {
            print("ERROR:\tCouldn't find username and/or domain")
            return nil
        }
    }
    
    func colorForScore(score: Int) -> Color {
        switch score {
        case 5:
            return .green
        case 4:
            return .mint
        case 3:
            return .yellow
        case 2:
            return .orange
        case 1:
            return .red
        default:
            return .background
        }
    }
    
    @ViewBuilder
    var enterPasswordView: some View {
        VStack {
            BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                .frame(width: 125, height: 43)
                .padding(.bottom, 30)
            
            Label("NOTICE: If you forget your passphrase, you won't be able to access your posts or photos on a new device.", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                .foregroundColor(.red)
                .font(CustomFonts.nunito14)
                .padding(.horizontal, 12)

            VStack(alignment: .leading) {
                Text("Set Passphrase")
                    .font(
                        CustomFonts.nunito20
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                    .padding(.top, 16)
                
                SecureFieldWithEye(label: "New Passphrase", isNewPassword: true,
                                   text: $passphrase, showText: showPassword)
                    .frame(height: buttonHeight)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: passphrase) { newPassword in
                        if newPassword.isEmpty {
                            score = 0.0
                            color = .red
                        }
                        else if let result = checker.passwordStrength(newPassword) {
                            print("Password score: \(result.score)")
                            score = Double(min(result.score, 4)) + 1
                            color = colorForScore(score: Int(score))
                        }
                        else {
                            score = 1.0
                            color = .red
                        }
                        //.frame(width: 350.0, height: 40.0)
                }
                
                ProgressView("Strength", value: 1.0 * self.score, total: 5.0)
                    .tint(self.color)
                    .foregroundColor(.gray)
            }
            .frame(width: buttonWidth)

            Spacer()
            
            Button(action: {
                self.screen = .savePassword
            }) {
                Text("Submit")
            }
            .buttonStyle(BigRoundedButtonStyle(width: buttonWidth, height: buttonHeight))
            .font(
                CustomFonts.nunito16
                    .weight(.bold)
            )
            .padding(.bottom, 38)
            .disabled(passphrase.isEmpty || score < MINIMUM_PASSWORD_ZXCVBN_SCORE)
        }
    }
    
    func submit() async throws {
        guard let userId = getUserId()
        else {
            print("Couldn't get user id")
            return
        }
        try await session.doBSSpekeEnrollOprfStage(userId: userId, password: passphrase)
    }
    
    @ViewBuilder
    var savePasswordView: some View {
        VStack(spacing: 20) {
            let elementWidth = UIScreen.main.bounds.width - 48
            let buttonHeight: CGFloat = 48.0
            let signUpButtonStyle = BigRoundedButtonStyle(width: buttonWidth,
                                                          height: buttonHeight,
                                                          color: Color.accentColor)
            
            Text("Would you like to save your passphrase to iCloud Keychain?")
                .font(
                    CustomFonts.nunito14
                        .weight(.semibold)
                )
                .frame(width: elementWidth)
                .multilineTextAlignment(.leading)
                .padding(.top, 16)
            
            Spacer()
            
            AsyncButton(action: {
                session.savePasswordToKeychain()
                try await submit()
            }) {
                Text("Save passphrase")
            }
            .buttonStyle(signUpButtonStyle)
            .font(
                CustomFonts.nunito16
                    .weight(.bold)
            )
            
            AsyncButton(action: {
                try await submit()
            }) {
                Text("Don't save my passphrase")
            }
            .buttonStyle(signUpButtonStyle)
            .font(
                CustomFonts.nunito16
                    .weight(.bold)
            )
        }
    }
    
    var body: some View {
        VStack {
            switch screen {
            case .enterPassword:
                enterPasswordView
            case .savePassword:
                savePasswordView
            }
        }
    }
}
