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

    #if DEBUG
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 2.0
    #else
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 3.0
    #endif
    
    @State var showRepeat = false
    
    enum FocusField {
        case inputPassphrase
        case repeatPassphrase
    }
    @FocusState var focus: FocusField?
    
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
    var passwordView: some View {
        VStack {
            Spacer()

            Text("Set Passphrase")
                .font(.title2)
                .fontWeight(.bold)
            
            Label("WARNING: If you forget your passphrase, you won't be able to access your posts or photos on a new device.", systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
                .padding(.top)
            
            Spacer()

            VStack(alignment: .leading) {
                SecureField("correct horse battery staple", text: $passphrase, prompt: Text("New passphrase"))
                    .textContentType(.newPassword)
                    .focused($focus, equals: .inputPassphrase)
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
                    }
                    .frame(width: 300.0, height: 40.0)
                
                ProgressView("Strength", value: 1.0 * self.score, total: 5.0)
                    .tint(self.color)
            }
            .frame(maxWidth: 550)
            .padding()


            Spacer()

            Button(action: {
                self.showRepeat = true
            }) {
                Text("Next")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(passphrase.isEmpty || score < MINIMUM_PASSWORD_ZXCVBN_SCORE)
        }
    }
    
    @ViewBuilder
    var repeatPasswordView: some View {
        VStack {
            Spacer()
            Text("Confirm Passphrase")
                .font(.title2)
                .fontWeight(.bold)
            Text("or")
            Button(action: {
                self.passphrase = ""
                self.score = 0.0
                self.color = .red
                self.showRepeat = false
            }) {
                Label("Choose a different passphrase", systemImage: "arrowshape.turn.up.backward.fill")
            }
            Spacer()

            SecureField("same passphrase as before", text: $repeatPassphrase, prompt: Text("Repeat passphrase"))
                .textContentType(.newPassword)
                .focused($focus, equals: .repeatPassphrase)
                .frame(width: 300.0, height: 40.0)
                

            Spacer()
            
            AsyncButton(action: {
                guard let userId = getUserId()
                else {
                    print("Couldn't get user id")
                    return
                }
                try await session.doBSSpekeEnrollOprfStage(userId: userId, password: passphrase)
            }) {
                Text("Submit")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(passphrase.isEmpty || passphrase != repeatPassphrase || score < MINIMUM_PASSWORD_ZXCVBN_SCORE)
        }
        .padding()
    }
    
    
    var body: some View {
        VStack {
            if passphrase.isEmpty || showRepeat == false {
                passwordView
                    .onAppear {
                        self.focus = .inputPassphrase
                    }
            } else {
                repeatPasswordView
                    .onAppear {
                        self.focus = .repeatPassphrase
                    }
            }
            
        }
    }
}
