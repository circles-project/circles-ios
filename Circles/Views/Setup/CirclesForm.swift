//
//  CirclesForm.swift
//  Circles
//
//  Created by Charles Wright on 9/7/21.
//

import SwiftUI
import PhotosUI
import Matrix

struct CirclesForm: View {
    var session: SetupSession
    let displayName: String

    @State var friendsAvatar: UIImage?
    @State var familyAvatar: UIImage?
    @State var communityAvatar: UIImage?

    let stage = "circles"

    var body: some View {
        VStack(alignment: .center) {
            //let currentStage: SignupStage = .setupCircles

            Text("Setup your circles")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            VStack(alignment: .leading) {
                // FIXME lol what's a ForEach?
                // But seriously it's unreasonably difficult to
                // iterate over a Dictionary containing bindings.
                // So, sigh, f*** it.  We can do it the YAGNI way.
                SetupCircleCard(session: session, circleName: "Friends", userDisplayName: self.displayName, avatar: self.$friendsAvatar)
                Divider()

                SetupCircleCard(session: session, circleName: "Family", userDisplayName: self.displayName, avatar: self.$familyAvatar)
                Divider()

                SetupCircleCard(session: session, circleName: "Community", userDisplayName: self.displayName, avatar: self.$communityAvatar)
                Divider()
            }

            Label("NOTE: Circle names and cover images are not encrypted", systemImage: "exclamationmark.shield")
                .font(.headline)
                .foregroundColor(.orange)

            Spacer()

            AsyncButton(action: {
                let circlesInfo: [SetupSession.CircleInfo] = [
                    SetupSession.CircleInfo(name: "Friends", avatar: friendsAvatar),
                    SetupSession.CircleInfo(name: "Family", avatar: familyAvatar),
                    SetupSession.CircleInfo(name: "Community", avatar: communityAvatar),
                ]
                
                do {
                    try await session.setupCircles(circlesInfo)
                } catch {
                    
                }

            }) {
                Text("Next")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }

        }
        .padding()
    }

}

/*
struct CirclesForm_Previews: PreviewProvider {
    static var previews: some View {
        CirclesForm()
    }
}
*/
