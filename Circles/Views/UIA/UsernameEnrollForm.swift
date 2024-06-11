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
        VStack(alignment: .center, spacing: 40) {
            Spacer()

            Text("Choose a username")
                .font(.title2)

            TextField("Username", text: $username, prompt: Text("username"))
                .textContentType(.username)
                .focused($focus, equals: .username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)
                .onAppear {
                    self.focus = .username
                }
            
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
                    print("SIGNUP/Username\tExisting username = \(session.realRequestDict["username"] as? String)")
                }

            }) {
                Text("Submit")
            }
            .buttonStyle(BigBlueButtonStyle())
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .cancel(Text("OK"))
                )
            }
            
            //Spacer()
        }
    }
}
