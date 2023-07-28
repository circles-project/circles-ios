//
//  RoomMemberRow.swift
//  Circles
//
//  Created by Charles Wright on 7/28/23.
//

import SwiftUI
import Matrix

struct RoomMemberRow: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var room: Matrix.Room
    var editable: Bool = false
    //var initialAccess: Int = 0
    
    let roles: [String] = ["Can View", "Can Post", "Moderator", "Owner"]
    var powerLevels: [Int] = [0, 10, 50, 100]
    
    var accessLevel: Int {
        let power = room.getPowerLevel(userId: user.userId)
        //return power
        
        let maybeAccess = powerLevels.lastIndex { level in
            let result = level <= power
            //print("Level = \(level), Power = \(power), \(result)")
            return result
        }
        
        guard let access = maybeAccess else {
            return 0
        }
        
        return access
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                MessageAuthorHeader(user: user)
                Spacer()
                
                Text(roles[accessLevel])
                //Text("\(accessLevel)")
                    .font(.subheadline)
            }
            .contextMenu(menuItems: {
                Menu("Set Access Level") {
                    ForEach(0 ..< roles.count) { index in
                        AsyncButton(action: {
                            //self.selection = index
                            // FIXME Actually make the Matrix API call to change the access level
                            try await room.setPowerLevel(userId: user.userId, power: powerLevels[index])
                        }) {
                            Text(roles[index])
                        }
                    }
                }
                Menu("Moderation") {

                    // Philosophical question: What does it mean to "mute" a user here???
                    //  * Does it mean just removing their ability to post in my room? (If this is a Circle, and we're following them, we'll still see their posts in their own Room.  But our other followers will no longer have to see anything from them.  Maybe that's what we want.  But then why not just change their access to "Can View" above?
                    //  * Does it mean allowing them to post, but hiding their posts from *me*?  (This version makes no sense when I'm the room owner.)
                    // In any case, it probably makes sense to do this somewhere else, ie the context menu on a post
                    AsyncButton(action: {
                        try await room.mute(userId: user.userId)
                    }) {
                        Text("Mute this user")
                        Image(systemName: "speaker.slash")
                    }
                    
                    AsyncButton(action: {
                        try await room.kick(userId: user.userId)
                    }) {
                        Text("Remove this user")
                        Image(systemName: "person.fill.xmark")
                    }
                    AsyncButton(action: {
                        try await room.ban(userId: user.userId)
                    }) {
                        Text("Ban this user forever")
                        Image(systemName: "xmark.shield")
                    }
                }
            })
        }

    }
}

/*
struct RoomMemberRow_Previews: PreviewProvider {
    static var previews: some View {
        RoomMembersRow()
    }
}
*/
