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
    
    @State var showConfirmLeave = false

    var body: some View {
        HStack(alignment: .center) {
            RoomAvatarView(room: room, avatarText: .oneLetter)
                .frame(width: 80, height: 80)
                .padding(.leading, 5)
            
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 3) {
                    Text(room.name ?? room.id)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.greyCool1000)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(.bottom, 4)

                VStack(alignment: .leading) {
                    if DebugModel.shared.debugMode {
                        Text(room.roomId.stringValue)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    HStack(spacing: 12  ) {
                        HStack(spacing: 2) {
                            Text("\(Image(systemName: "person.2"))")
                            Text("\(room.joinedMembers.count)")
                        }
                        
                        if room.unread > 0 {
                            HStack(spacing: 2) {
                                Text("\(Image(systemName: "circle.fill"))")
                                Text("\(room.unread)")
                            }
                        } else {
                            let formattedTimestamp = RelativeTimestampFormatter.format(date: room.timestamp)
                            HStack(spacing: 2) {
                                Text("\(Image(systemName: "clock"))")
                                Text(formattedTimestamp)
                            }
                        }
                    }
                                        
                    let knockCount = room.knockingMembers.count
                    if room.iCanInvite && room.iCanKick && knockCount > 0 {
                        let color = Color(light: .accentColor, dark: .white)
                        Label("\(knockCount) request(s) for invitation", systemImage: "star.fill")
                            .foregroundColor(color)
                    }
                }
                .font(.footnote)
                .foregroundColor(.greyCool800)
            }
            .padding(.top, 5)
        }
        .contextMenu {
            Button(role: .destructive, action: {
                self.showConfirmLeave = true
            }) {
                Label("Leave group", systemImage: SystemImages.xmarkBin.rawValue)
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
