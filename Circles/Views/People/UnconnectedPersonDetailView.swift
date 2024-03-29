//
//  UnconnectedPersonDetailView.swift
//  Circles
//
//  Created by Charles Wright on 7/31/23.
//

import SwiftUI
import Matrix

struct UnconnectedPersonDetailView: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var myProfileRoom: Matrix.Room
    @State var mutualFriends: [Matrix.User]? = nil

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    var status: some View {
        HStack {
            Text("Latest Status:")
                .fontWeight(.bold)
            Text(user.statusMessage ?? "(no status message)")
        }
        .font(.subheadline)
    }
    
    var header: some View {
        HStack {
            Spacer()
            
            VStack {
                UserAvatarView(user: user)
                    .frame(width: 160, height: 160, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                //.padding(.leading)
                Text(user.displayName ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                Text(user.userId.stringValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                AsyncButton(action: {
                    do {
                        try await myProfileRoom.invite(userId: user.userId)
                    } catch {
                        print("UnconnectedPersonDetailView - ERROR:\t \(error)")

                        self.alertTitle = "Request failed"
                        self.alertMessage = "An unknown error has occurred. Please try again later."
                        self.showAlert = true
                    }
                }) {
                    Label("Invite to connect", systemImage: "link")
                }
                .padding(5)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertTitle),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    var mutualFriendsSection: some View {
        LazyVStack(alignment: .leading) {
            Text("MUTUAL FRIENDS")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top)
            if let friends = mutualFriends {
                if friends.isEmpty {
                    Text("No mutual friends")
                        .padding()
                } else {
                    ForEach(friends) { friend in
                        HStack {
                            UserAvatarView(user: friend)
                                .frame(width: 80, height: 80)
                            
                            VStack(alignment: .leading) {
                                Text(friend.displayName ?? friend.userId.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(friend.userId.stringValue)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                let session = user.session
                // First find the set of circles that we're both in
                let rooms: [Matrix.Room] = session.rooms.values.filter { room in
                    room.type == ROOM_TYPE_CIRCLE && room.joinedMembers.contains(user.userId)
                }
                // Find the users in those circles who are not (1) me or (2) them
                let users: Set<Matrix.User> = rooms.reduce([], { curr, room in
                    let roomMembers: [Matrix.User] = room.joinedMembers.filter {
                        $0 != user.userId && $0 != user.session.creds.userId
                    }.compactMap {
                        session.getUser(userId: $0)
                    }
                    return curr.union(roomMembers)
                })
                // Sort the set in order to get an Array
                let sortedUsers = users.sorted(by: {u0,u1 in
                    u0.userId.stringValue < u1.userId.stringValue
                })
                // Update the UI state on the main thread
                await MainActor.run {
                    self.mutualFriends = sortedUsers
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                header

                //status
                
                Divider()
            
                mutualFriendsSection
            
            }
        }
        .padding()
        .onAppear {
            // Hit the Homeserver to make sure we have the latest
            //user.matrix.getDisplayName(userId: user.id) { _ in }
            user.refreshProfile()
        }
        .navigationTitle(Text(user.displayName ?? user.userId.username))
    }
}

/*
struct UnconnectedPersonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UnconnectedPersonDetailView()
    }
}
*/
