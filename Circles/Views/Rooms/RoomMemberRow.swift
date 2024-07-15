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
    
    @State var showConfirmModerateSelf = false
    @State var newPowerLevel: Int?
    
    let roles: [String] = ["Can View", "Can Post", "Moderator", "Owner"]
    var powerLevels: [Int] = [-10, 0, 50, 100]
    
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
    
    @ViewBuilder
    var menu: some View {
        let myPowerLevel = room.myPowerLevel
        let theirPowerLevel = room.getPowerLevel(userId: user.userId)
        let iCanModerateThem = myPowerLevel >= theirPowerLevel
        
        if room.iCanChangeState(type: M_ROOM_POWER_LEVELS) && iCanModerateThem {
            Menu("Set Access Level") {
                ForEach(0 ..< roles.count, id: \.self) { index in
                    AsyncButton(action: {
                        // Check yourself before you wreck yourself -- Are we setting our own power level here?
                        if user.userId == room.session.creds.userId {
                            // If so, then we should confirm that this is really what the user wants to do
                            await MainActor.run {
                                self.showConfirmModerateSelf = true
                                self.newPowerLevel = powerLevels[index]
                            }
                        } else {
                            // If not, we're moderating someone else -- fire away!
                            try await room.setPowerLevel(userId: user.userId, power: powerLevels[index])
                        }
                    }) {
                        Text(roles[index])
                    }
                    .disabled(myPowerLevel < powerLevels[index])
                }
            }
        }
        
        // Check yourself before you wreck yourself
        if user.userId != room.session.creds.userId {
            Menu("Moderation") {
                AsyncButton(action: {
                    try await room.session.ignoreUser(userId: user.userId)
                }) {
                    Label("Ignore this user", systemImage: "person.slash")
                }
                
                if iCanModerateThem {
                    
                    if room.iCanChangeState(type: M_ROOM_POWER_LEVELS) {
                        AsyncButton(action: {
                            try await room.mute(userId: user.userId)
                        }) {
                            Text("Mute this user here")
                            Image(systemName: SystemImages.speakerSlash.rawValue)
                        }
                    }
                    
                    if room.iCanKick {
                        AsyncButton(action: {
                            try await room.kick(userId: user.userId)
                        }) {
                            Text("Remove this user")
                            Image(systemName: SystemImages.personFillXmark.rawValue)
                        }
                    }
                    
                    if room.iCanBan {
                        AsyncButton(action: {
                            try await room.ban(userId: user.userId)
                        }) {
                            Text("Ban this user forever")
                            Image(systemName: SystemImages.xmarkShield.rawValue)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                UserAvatarView(user: user)
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading) {
                    UserNameView(user: user)
                    Text(user.userId.stringValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .contextMenu { menu }
            .confirmationDialog(
                "Change your own access level?",
                isPresented: $showConfirmModerateSelf,
                actions: {
                    AsyncButton(action: {
                        if let power = self.newPowerLevel {
                            let myUserId = room.session.creds.userId
                            try await room.setPowerLevel(userId: myUserId, power: power)
                        }
                    }) {
                        Text("Change my access level")
                    }
                }, message: {
                    Label("WARNING!  You are modifying your own access level.  This change cannot be undone.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            )
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
