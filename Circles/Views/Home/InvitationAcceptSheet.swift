//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  InvitationAcceptSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/9/20.
//

import SwiftUI
import Matrix

struct InvitationAcceptSheet: View {
    //@EnvironmentObject var store: KSStore
    @ObservedObject var container: ContainerRoom<CircleSpace>
    @ObservedObject var room: Matrix.InvitedRoom
    @Environment(\.presentationMode) var presentation
    @State var selected: Set<CircleSpace> = []
    @State var inviteBack = false
    
    var body: some View {
        VStack {
            let inviterId = room.sender
            let inviter = room.session.getUser(userId: inviterId)
            
            Text("You are now following:")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            HStack {
                ZStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color.gray)
                    
                    Image(uiImage: room.avatar ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        //.clipped()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(5)
                }
                VStack {

                    //MessageAuthorHeader(user: inviter)
                    Text("\(inviter.displayName ?? inviter.id):")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(room.name ?? room.roomId.description)
                        .font(.title2)
                        .fontWeight(.bold)
                        //.foregroundColor(Color.white)
                        //.shadow(color: .black, radius: 3)
                }
            }
            
            //Text("You have been invited to follow the channel \"\(room.displayName ?? room.id)\"")
            
            Spacer()
                        
            Text("You can also connect this Circle to see updates in one of your Circles.")
                //.padding(.horizontal)
            CirclePicker(container: container, selected: $selected)
            Toggle("Also invite \(inviter.displayName ?? inviter.userId.description) to follow me here", isOn: $inviteBack)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

            Spacer()
            
            
            AsyncButton(action: {
                
                for space in container.rooms {
                    try await space.addChildRoom(room.roomId)

                    if self.inviteBack {
                        print("Inviting user \(inviter.userId) to follow us on \(space.name)")
                        try await space.wall?.invite(userId: inviter.userId)
                    }
                }

            }) {
                Image(systemName: "checkmark")
                Text("Done")
            }
            .padding()

        }
        .padding()
    }
}
