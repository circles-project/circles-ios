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
    
    var timestamp: some View {
        let formatter = RelativeDateTimeFormatter()
        if let date = room.latestMessage?.timestamp {
            return Text("Last updated \(date, formatter: formatter)")
        } else {
            return Text("")
        }
    }
    
    
    var body: some View {
        HStack(alignment: .top) {
            RoomAvatar(room: room)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 3) {
                    Text(room.name ?? room.id)
                        .fontWeight(.bold)
                    Spacer()
                }
                .font(.title2)

                VStack(alignment: .leading) {
                    Text("\(room.joinedMembers.count) members")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    timestamp
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if debugMode {
                        Text(room.roomId.description)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.top, 5)
        }
        .contextMenu {
            Button(role: .destructive, action: {
                showConfirmLeave = true
            }) {
                Label("Leave group", systemImage: "xmark.bin")
            }
        }
        .confirmationDialog(Text("Confirm Leaving Group"),
                            isPresented: $showConfirmLeave,
                            actions: { //rm in
                                AsyncButton(role: .destructive, action: {
                                    try await container.leaveChildRoom(room.roomId)
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
