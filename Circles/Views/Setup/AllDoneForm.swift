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
    let userId: UserId

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
            Text("\(userId.description)")
                    .fontWeight(.bold)

            Spacer()

            AsyncButton(action: {
                do {
                    try await store.disconnect()
                } catch {
                    
                }
            }) {
                Text("Next: Log in")
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
