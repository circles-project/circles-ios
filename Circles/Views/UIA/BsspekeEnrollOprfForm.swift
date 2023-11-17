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
    @State var password: String = ""
    @State var repeatPassword: String = ""
    //@State var passwordStrength: Int = 0
    @State var score: Int = 1
    @State var passwordStrengthColors: [Color] = []
    let checker = DBZxcvbn()

    #if DEBUG
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 2
    #else
    let MINIMUM_PASSWORD_ZXCVBN_SCORE = 4
    #endif
    
    private func getUserId() -> UserId? {
        if let userId = session.creds?.userId {
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
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Set Passphrase")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .leading) {
                HStack {
                    Text("Strength:")
                    ForEach(passwordStrengthColors, id: \.self) { color in
                        //RoundedRectangle(cornerRadius: 8)
                        Rectangle()
                            .fill(color)
                            .frame(width: 20, height: 40)
                    }
                }

                SecureField("correct horse battery staple", text: $password, prompt: Text("New passphrase"))
                    .textContentType(.newPassword)
                    .onChange(of: password) { newPassword in
                        if let result = checker.passwordStrength(newPassword) {
                            print("Password score: \(result.score)")
                            score = Int(min(result.score, 4)) + 1
                            let color = colorForScore(score: score)
                            self.passwordStrengthColors = Array<Color>.init(repeating: color, count: score) + Array<Color>.init(repeating: .background, count: 5-score)
                        } else {
                            self.passwordStrengthColors = []
                        }
                    }
                    .frame(width: 300.0, height: 40.0)
                SecureField("correct horse battery staple", text: $repeatPassword, prompt: Text("Repeat passphrase"))
                    .textContentType(.newPassword)
                    .frame(width: 300.0, height: 40.0)
                AsyncButton(action: {
                    guard let userId = getUserId()
                    else {
                        print("Couldn't get user id")
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
                .disabled(password.isEmpty || password != repeatPassword || score < MINIMUM_PASSWORD_ZXCVBN_SCORE)
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
