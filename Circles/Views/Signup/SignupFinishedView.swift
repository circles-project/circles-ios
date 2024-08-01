//
//  SignupFinishedView.swift
//  Circles
//
//  Created by Charles Wright on 8/1/23.
//

import SwiftUI
import Matrix

struct SignupFinishedView: View {
    var creds: Matrix.Credentials
    var key: Matrix.SecretStorageKey?
    var store: CirclesStore

    var body: some View {
        ZStack {
            Color.greyCool200
            
            VStack {
                let buttonWidth = UIScreen.main.bounds.width - 48
                let buttonHeight: CGFloat = 48.0
                
                BasicImage(name: SystemImages.launchLogoPurple.rawValue)
                    .frame(width: 125, height: 43)
                    .padding(.top, 115)
                    .padding(.bottom, 30)
                
                Text("Successfully signed up!")
                    .font(
                        CustomFonts.nunito20
                            .weight(.heavy)
                    )
                    .foregroundColor(Color.greyCool1100)
                    .padding(.bottom, 8)
                
                HStack {
                    Text("Your new user ID is:")
                        .font(CustomFonts.nunito14)
                        
                    Text(creds.userId.stringValue)
                        .font(CustomFonts.nunito14.bold())
//                    Text(creds.userId.stringValue)
//                        .padding(.leading)
//                        .padding(.top)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
//                .padding(.vertical, 20)
                
                Text("Your user ID works like a username or an email address. Friends will need your user ID in order to invite you to follow them.")
                    .font(CustomFonts.nunito14)
                    .padding(.horizontal, 12)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                AsyncButton(action: {
                    do {
                        try await store.connect(creds: creds, s4Key: key)
                    } catch {
                        print("Failed to connect with creds for user \(creds.userId)")
                    }
                }) {
                    Text("Next: Set up your account")
                }
                .buttonStyle(BigRoundedButtonStyle(width: buttonWidth, height: buttonHeight))
                .font(
                    CustomFonts.nunito16
                        .weight(.bold)
                )
                .padding(.bottom, 38)
            }
//            .padding()
        }
        .background(Color.greyCool200)
    }
}

