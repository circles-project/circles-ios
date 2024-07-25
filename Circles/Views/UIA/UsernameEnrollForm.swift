//
//  UsernameEnrollForm.swift
//  Circles
//
//  Created by Charles Wright on 3/31/23.
//

import Foundation
import SwiftUI
import Matrix

struct UsernameEnrollForm: View {
    var session: SignupSession
    @State var username: String = ""
    
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    enum FocusField {
        case username
    }
    @FocusState var focus: FocusField?
    
    var body: some View {
        let screenWidthWithOffsets = UIScreen.main.bounds.width - 48
        BasicImage(name: SystemImages.launchLogoPurple.rawValue)
            .frame(width: 125, height: 43)
            .padding(.bottom, 30)
        
        VStack(alignment: .leading) {
            Text("Choose your User ID")
                .font(
                    CustomFonts.nunito14
                        .weight(.bold)
                )
                .foregroundColor(Color.greyCool1100)
                .frame(height: 30)
            
            TextField("@username:us.domain.com", text: $username)
                .frame(width: screenWidthWithOffsets, height: 48.0)
                .padding([.horizontal], 12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor))
                .textContentType(.username)
                .focused($focus, equals: .username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onAppear {
                    self.focus = .username
                }
        }
        
        Spacer()
        
        AsyncButton(action: {
            do {
                try await session.doUsernameStage(username: username)
            } catch {
                // Tell the user that we hit an error
                print("SIGNUP/Username\tUsername stage failed")
                await MainActor.run {
                    self.alertTitle = "Username Unavailable"
                    self.alertMessage = "The requested username is not available.  Please try a different one."
                    self.showAlert = true
                }
                print("SIGNUP/Username\tExisting username = \(session.realRequestDict["username"] as? String ?? "Error")")
            }
        }) {
            Text("Sign Up")
        }
        .buttonStyle(BigRoundedButtonStyle(width: screenWidthWithOffsets, height: 48))
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle),
                  message: Text(alertMessage),
                  dismissButton: .cancel(Text("OK"))
            )
        }
    }
}
