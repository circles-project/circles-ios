//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  RoomMembersSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/10/20.
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
    //var selection: Int
    //@State private var showPicker = false
    
    /* // WTF Swift
       // This feels like a bug.  Unless I'm missing something, the behavior
       // doesn't seem to match the description here:
       //   https://docs.swift.org/swift-book/LanguageGuide/Initialization.html
       // Instead, the init function never updates the first value from when
       // the variable was initialized.  Or else, we get a compile error that
       // (some variable, maybe not the one being initialized) was used before
       // initialization.  Argh.
       // For now, the practical solution is to compute whatever we need to
       // compute in the parent view.  Then we simply display it here.
    init(user u: MatrixUser, room r: MatrixRoom, editable e: Bool = false, initialPower: Int = 0) {
        
        /*
        let s = powerLevels.lastIndex { level in
            let result = level <= initialPower
            print("Level = \(level), Power = \(initialPower), \(result)")
            return result
        } ?? 3
        */
        
        self.user = u
        self.room = r
        //self.editable = e
        //self.initialPower = initialPower
        self.selection = 1
        
        let s = 3
        
        self.selection = 3
            

        //print("User \(u.id) has power \(initialPower) = index \(selection) or \(s) ")

    }
    */
    
    /*
    init(user u: MatrixUser, room r: MatrixRoom, initialPower: Int = 0) {
        self.user = u
        self.room = r
        self.initialAccess = initialPower
        
        self.selection = initialPower  // Compile error: "Variable self.selection used before being initialized".  But it only happens if 'selection' is a @State variable.  Hmmm...
    }
    */
    
    // FIXME: New idea for connecting the UI to the back-end
    //
    // From the parent, pass in (a container for?) sets of users to be
    // given each access level.  Like: viewers, posters, moderators, owners.
    // Then, when we close out the Picker, we put the user into whichever
    // bucket the user picked for them.
    //
    // FIXME: Alternatively, screw this Picker crap.  Just use the context menu.
    
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



struct RoomMembersSheet: View {
    @ObservedObject var room: Matrix.Room
    var title: String? = nil
    @Environment(\.presentationMode) var presentation

    @State var members: [Matrix.User] = []

    @State var showInviteSheet = false
    @State var currentToBeRemoved: [Matrix.User] = []
    @State var showConfirmRemove = false
    
    @State var currentMembers: [Matrix.User] = []
    @State var invitedMembers: [Matrix.User] = []
    
    /*
    init(room: MatrixRoom) {
        self.room = room
        //self.currentMembers = room.joinedMembers
        //self.invitedMembers = room.invitedMembers
    }
    */
    
    var buttonBar: some View {
        HStack {
            /*
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            */
            
            Spacer()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }){
                Text("Done")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
    }
    
    func kickUsers() async throws {
        for user in self.currentToBeRemoved {
            try await room.kick(userId: user.userId)
        }
    }
    
    func banUsers() async throws {
        for user in self.currentToBeRemoved {
            try await room.ban(userId: user.userId)
        }
    }
    
    var currentMemberSection: some View {
        Section(header: Text("Current")) {
            ForEach(room.joinedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
                    .actionSheet(isPresented: $showConfirmRemove) {
                        return ActionSheet(title: Text("Remove Users?"),
                                    message: Text("Are you sure you want to remove \(currentToBeRemoved.count) user(s)?"),
                                    buttons: [
                                        .default(Text("Kick Them Out")) {
                                            //kickUsers()
                                            currentMembers.removeAll(where: {u in
                                                self.currentToBeRemoved.contains(u)
                                            })
                                            //current = room.joinedMembers
                                            self.currentToBeRemoved.removeAll()
                                        },
                                        .default(Text("Ban Them")) {
                                            //banUsers()
                                            currentMembers.removeAll(where: {u in
                                                self.currentToBeRemoved.contains(u)
                                            })
                                            self.currentToBeRemoved.removeAll()
                                        },
                                        .cancel() {
                                            self.currentToBeRemoved.removeAll()
                                        }
                                    ])
                    }
            }
            .onDelete { indexes in
                for index in indexes {
                    self.currentToBeRemoved.append(currentMembers[index])
                }
                //self.showConfirmRemove = true
                currentMembers.remove(atOffsets: indexes)
            }
        }
    }
    
    var invitedMemberSection: some View {
        Section(header: Text("Invited")) {
            ForEach(room.invitedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
            }
        }
    }
    
    var bannedMemberSection: some View {
        Section(header: Text("Banned")) {
            ForEach(room.bannedMembers) { userId in
                let user = room.session.getUser(userId: userId)
                RoomMemberRow(user: user, room: room)
            }
        }
    }
    
    var body: some View {
        VStack {
            
            buttonBar

            /*
            Button(action: {
                self.room.getRoomType() { response in
                    switch response {
                    case .failure:
                        print("ROOMTYPE\tFailed to get room type for room [\(room.displayName ?? room.id)]")
                    case .success(let roomType):
                        print("ROOMTYPE\tRoom [\(room.displayName ?? room.id)] has type [\(roomType)]")
                    }
                }
            }) {
                Text("Run Tests")
            }
            */
            
            Text(title ?? "Followers for \(room.name ?? "this room")")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            Spacer()
            
            VStack(alignment: .leading) {
                //let haveModPowers = room.amIaModerator()

                List {
                    currentMemberSection

                    if !room.invitedMembers.isEmpty {
                        invitedMemberSection
                    }

                    if !room.bannedMembers.isEmpty {
                        bannedMemberSection
                    }
                }
            }

        }
        .padding()
        /*
        .onAppear {

            var doThisManually = false
            if !doThisManually {

                // Let's at least try this the SwiftUI way
                room.updateMembers()
                // Then if it fails, we can do the "manually update the UI" way below...
                // Yeah that fails to do anything...  argh.
                // (The problem seems to be that I'm holding on to some MX data structure in the MatrixRoom, and for whatever reason it's not getting refreshed.)
            } else {
                room.asyncMembers { response in
                    switch response {
                    case .failure(let err):
                        print("MEMBERS\tFailed to get member list for room \(room.displayName) (\(room.id) -- \(err)")
                        return
                    case .success(let memberList):
                        print("MEMBERS\tSucces!  Got \(memberList.count) room members for room \(room.id)")
                        self.members = memberList
                    }
                }
            }

            // Either way, let's use my new MatrixInterface method to poll the homeserver directly

            room.matrix.fetchRoomMemberList(roomId: room.id) { response in
                guard case let .success(newMembers) = response else {
                    print("MEMBERS\tNew method for getting room members from the homeserver failed")
                    return
                }
                print("MEMBERS\tGot \(newMembers.count) members from the homeserver")
            }
        }
        */
    }
}

/*
struct ChannelMembersSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChannelMembersSheet()
    }
}
 */
