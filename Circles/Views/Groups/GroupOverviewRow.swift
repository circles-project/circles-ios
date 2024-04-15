//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupOverviewRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 7/29/20.
//

import SwiftUI
import Matrix

struct GroupOverviewRow: View {
    var container: ContainerRoom<GroupRoom>
    @ObservedObject var room: Matrix.Room
    @AppStorage("debugMode") var debugMode: Bool = false
    
    @State var showConfirmLeave = false

    var body: some View {
        HStack(alignment: .top) {
            RoomAvatarView(room: room, avatarText: .roomInitials)
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.leading, 5)
            
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 3) {
                    Text(room.name ?? room.id)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }

                VStack(alignment: .leading) {
                    
                    if debugMode {
                        Text(room.roomId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Text("\(room.joinedMembers.count) member(s)")

                    
                    let knockCount = room.knockingMembers.count
                    if room.iCanInvite && room.iCanKick && knockCount > 0 {
                        let color = Color(light: .accentColor, dark: .white)
                        Label("\(knockCount) requests for invitations", systemImage: "star.fill")
                            .foregroundColor(color)
                    }
                    
                    if room.unread > 0 {
                        Text("\(room.unread) unread posts")
                            .fontWeight(.bold)
                    } else {
                        Text("Last updated \(room.timestamp, formatter: RelativeDateTimeFormatter())")
                    }

                }
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.leading, 8)
            }
            .padding(.top, 5)
        }
        .contextMenu {
            Button(role: .destructive, action: {
                self.showConfirmLeave = true
            }) {
                Label("Leave group", systemImage: "xmark.bin")
            }
        }
        .confirmationDialog(Text("Confirm Leaving Group"),
                            isPresented: $showConfirmLeave,
                            actions: { //rm in
                                AsyncButton(role: .destructive, action: {
                                    try await container.leaveChild(room.roomId)
                                }) {
                                    Text("Leave \(room.name ?? "this group")")
                                }
                            })
    }
}

/*
struct ChannelOverviewRow_Previews: PreviewProvider {
    static var previews: some View {
        ChannelOverviewRow()
    }
}
 */
