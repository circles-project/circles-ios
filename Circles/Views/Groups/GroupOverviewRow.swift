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

    var body: some View {
        HStack(alignment: .top) {
            RoomAvatar(room: room, avatarText: .roomInitials)
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 3) {
                    Text(room.name ?? room.id)
                        .fontWeight(.bold)
                    Spacer()
                }
                .font(.title2)

                VStack(alignment: .leading) {
                    
                    if debugMode {
                        Text(room.roomId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Text("\(room.joinedMembers.count) member(s)")

                    Text("Last updated \(room.timestamp, formatter: RelativeDateTimeFormatter())")
                    
                    //let knockCount = room.knockingMembers.count
                    let knockCount = Int.random(in: 2...10)
                    if room.iCanInvite && knockCount > 0 {
                        Label("\(knockCount) requests for invitations", systemImage: "star.fill")
                            .foregroundColor(.accentColor)
                    }

                }
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.leading, 8)
            }
            .padding(.top, 5)
        }
    }
}

/*
struct ChannelOverviewRow_Previews: PreviewProvider {
    static var previews: some View {
        ChannelOverviewRow()
    }
}
 */
