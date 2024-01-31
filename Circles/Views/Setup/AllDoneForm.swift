//
//  AllDoneForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import Matrix

struct AllDoneForm: View {
    var store: CirclesStore
    var matrix: Matrix.Client
    var config: CirclesConfigContent

    @State var pending = false

    var body: some View {
        VStack {
            //let currentStage: SignupStage = .validateToken

            Spacer()

            Text("Circles is all set up!")
                .font(.title)
                .fontWeight(.bold)


            Spacer()
            Text("Your user ID is:")
            Text("\(matrix.creds.userId.description)")
                    .fontWeight(.bold)

            Spacer()

            AsyncButton(action: {
                // Are we running on an already-fully-set-up account with a stateful session that's already running?
                if let session = matrix as? Matrix.Session {
                    // If so, then don't log us out -- just launch the full app interface
                    try await store.addConfig(config: config)
                } else {
                    // Otherwise, we must be running with a lightweight REST client in the setup UI
                    // Send the user back to the login screen
                    try await store.logout()
                }
            }) {
                Text("Get Started")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }


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
