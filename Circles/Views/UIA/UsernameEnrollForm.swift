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
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Choose a username")
                .font(.title2)
            Text("")
            TextField("Username", text: $username, prompt: Text("username"))
                .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                .disableAutocorrection(true)
                .frame(width: 300.0, height: 40.0)
            Spacer()
            
            AsyncButton(action: {
                
                do {
                    try await session.doUsernameStage(username: username)
                } catch {
                    // Tell the user that we hit an error
                    print("SIGNUP/Username\tUsername stage failed")
                    self.alertTitle = "Something went wrong"
                    self.alertMessage = "Failed to complete Username stage"
                    self.showAlert = true
                    print("SIGNUP/Username\tExisting username = \(session.realRequestDict["username"] as? String)")
                }

            }) {
                Text("Submit")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            /*
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .cancel(Text("OK"))
                )
            }
            */
        }
    }
}
