//
//  AllDoneForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI

struct AllDoneForm: View {
    var matrix: MatrixInterface
    let userId: String
    @Binding var uiaaState: UiaaSessionState?
    //@Binding var selectedScreen: LoggedOutScreen.Screen

    //@Binding var userId: String?

    @State var pending = false

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .validateToken

            Spacer()

            Text("Registration is complete!")
                .font(.title)
                .fontWeight(.bold)


            Spacer()
            Text("Your user ID is:")
            Text(userId)
                    .fontWeight(.bold)

            Spacer()

            Button(action: {
                //self.selectedScreen = .login
                self.pending = true
                //matrix.finishSignupAndConnect()
                //self.selectedScreen = .login

                // Nuke our UIAA session state, which will send the UI back to the login screen
                uiaaState = nil
            }) {
                Text("Next: Log in")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(pending)


            Spacer()
        }
    }
}

/*
struct AllDoneForm_Previews: PreviewProvider {
    static var previews: some View {
        AllDoneForm()
    }
}
*/
