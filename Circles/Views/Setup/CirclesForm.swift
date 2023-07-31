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
    @State var status: String = "Waiting for input"
    @State var pending = false

    let stage = "circles"

    var mainForm: some View {
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
                let circlesInfo: [CircleInfo] = [
                    CircleInfo(name: "Friends", avatar: friendsAvatar),
                    CircleInfo(name: "Family", avatar: familyAvatar),
                    CircleInfo(name: "Community", avatar: communityAvatar),
                ]
                
                pending = true
                do {
                    try await setupCircles(circlesInfo)
                } catch {
                    
                }
                pending = false
                
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
    
    struct CircleInfo {
        var name: String
        var avatar: UIImage?
    }
    
    func setupCircles(_ circles: [CircleInfo]) async throws {
        print("Creating Spaces hierarchy for Circles rooms")
        let client = session.client
        print("- Creating Space rooms")
        status = "Creating Matrix Spaces"
        let topLevelSpace = try await client.createSpace(name: "Circles")
        let myCircles = try await client.createSpace(name: "My Circles")
        let myGroups = try await client.createSpace(name: "My Groups")
        let myGalleries = try await client.createSpace(name: "My Photo Galleries")
        let myPeople = try await client.createSpace(name: "My People")
        let myProfile = try await client.createSpace(name: displayName)
        
        print("- Adding Space child relationships")
        status = "Initializing spaces"
        try await client.addSpaceChild(myCircles, to: topLevelSpace)
        try await client.addSpaceChild(myGroups, to: topLevelSpace)
        try await client.addSpaceChild(myGalleries, to: topLevelSpace)
        try await client.addSpaceChild(myPeople, to: topLevelSpace)
        try await client.addSpaceChild(myProfile, to: topLevelSpace)
        
        print("- Adding tags to spaces")
        status = "Tagging spaces"
        try await client.addTag(roomId: topLevelSpace, tag: ROOM_TAG_CIRCLES_SPACE_ROOT)
        try await client.addTag(roomId: myCircles, tag: ROOM_TAG_MY_CIRCLES)
        try await client.addTag(roomId: myGroups, tag: ROOM_TAG_MY_GROUPS)
        try await client.addTag(roomId: myGalleries, tag: ROOM_TAG_MY_PHOTOS)
        try await client.addTag(roomId: myPeople, tag: ROOM_TAG_MY_PEOPLE)
        try await client.addTag(roomId: myProfile, tag: ROOM_TAG_MY_PROFILE)
        
        print("- Uploading Circles config to account data")
        status = "Saving configuration"
        let config = CirclesConfigContent(root: topLevelSpace, circles: myCircles, groups: myGroups, galleries: myGalleries, people: myPeople, profile: myProfile)
        try await client.putAccountData(config, for: EVENT_TYPE_CIRCLES_CONFIG)
        
        for circle in circles {
            print("- Creating circle [\(circle.name)]")
            status = "Creating circle \"\(circle.name)\""
            let circleRoomId = try await client.createSpace(name: circle.name)
            let wallRoomId = try await client.createRoom(name: circle.name, type: ROOM_TYPE_CIRCLE)
            if let avatar = circle.avatar {
                try await client.setAvatarImage(roomId: wallRoomId, image: avatar)
            }
            try await client.addSpaceChild(wallRoomId, to: circleRoomId)
            try await client.addSpaceChild(circleRoomId, to: myCircles)
        }
        
        status = "All done!"
        await session.setAllDone()
    }
    
    var body: some View {
        ZStack {
            mainForm
            
            if pending {
                Color.gray.opacity(0.5)
                
                ProgressView {
                    Text("\(status)...")
                        .font(.headline)
                }
                .padding(20)
                .background(in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

}

/*
struct CirclesForm_Previews: PreviewProvider {
    static var previews: some View {
        CirclesForm()
    }
}
*/
