//
//  InvitedGroupDetailView.swift
//  Circles
//
//  Created by Charles Wright on 8/9/23.
//

import SwiftUI
import Matrix

struct InvitedGroupDetailView: View {
    @ObservedObject var room: Matrix.InvitedRoom
    @ObservedObject var user: Matrix.User
    @EnvironmentObject var matrix: Matrix.Session
    @State var showRoomIdPopover = false

    var body: some View {
        ScrollView {
            VStack {
                
                Text("You have been invited to:")
                    .padding()
  
                RoomAvatar(room: room, avatarText: .roomInitials)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary, lineWidth: 2))
                    .scaledToFit()
                    //.frame(width: 240, height: 240)
                    //.padding(-50)
                
                Text(room.name ?? "(unnamed group)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 20) {
                    GridRow {
                        Text("Group ID:")
                        
                        Button(action: { self.showRoomIdPopover = true }) {
                            Text(room.roomId.stringValue)
                                .multilineTextAlignment(.leading)
                                .truncationMode(.middle)
                                .lineLimit(1)
                            
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showRoomIdPopover) {
                            Text(room.roomId.stringValue)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    GridRow {
                        Text("Encrypted:")
                        Text(room.encrypted ? "Yes" : "No")
                    }
                    
                    GridRow {
                        Text("Invited by:")
                        VStack(alignment: .leading) {
                            Image(uiImage: user.avatar ?? UIImage(systemName: "person.circle") ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                //.frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            
                            Text("\(user.displayName ?? user.userId.username)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(user.userId.stringValue)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                Grid(alignment: .topLeading, horizontalSpacing: 10, verticalSpacing: 20) {

                    Divider()
                    
                    let followers = room.members.filter { $0 != user.userId }

                    
                    if followers.isEmpty {
                        GridRow {
                            Text("Followers:")
                            Text("unknown")
                        }
                    } else {
                        GridRow {
                            Text("Followers:")
                            Text("")
                        }
                        ForEach(followers) { followerId in
                            let follower = matrix.getUser(userId: followerId)
                            GridRow {
                                Text("")
                                MessageAuthorHeader(user: follower)
                            }
                        }
                    }
                }
                .padding()
                
                /*
                Divider()
                
                VStack {
                    
                    AsyncButton(action: {}) {
                        Label("Accept Invitation", systemImage: "hand.thumbsup.fill")
                            .padding()
                    }
                    
                    AsyncButton(role: .destructive, action: {}) {
                        Label("Reject Invitation", systemImage: "hand.thumbsdown.fill")
                            .padding()
                    }
                    
                    AsyncButton(role: .destructive, action: {}) {
                        Label("Ignore Invitation", systemImage: "xmark.bin")
                            .padding()
                    }
                } // end Vstack
                */
                
            } // end Vstack
        } // end ScrollView
        .navigationTitle(Text("Invitation Details"))
    } // end body
}

/*
struct InvitedGroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        InvitedGroupDetailView()
    }
}
*/
