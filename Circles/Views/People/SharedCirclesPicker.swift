//
//  AdvertisedCirclesPicker.swift
//  Circles
//
//  Created by Charles Wright on 11/6/23.
//

import SwiftUI
import Matrix

struct SharedCirclesPicker: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var circles: ContainerRoom<CircleSpace>
    @ObservedObject var profile: ProfileSpace
    
    var body: some View {
        VStack(alignment: .center) {

            Text("Select a Circle to share")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {

                LazyVStack(alignment: .leading) {
                    
                    let advertisedRoomIds: [RoomId] = Array(profile.rooms.keys)
                    
                    let rooms = circles.rooms.values.sorted { $0.timestamp < $1.timestamp }
                    
                    ForEach(rooms) { space in
                        if let wall = space.wall,
                           !advertisedRoomIds.contains(wall.roomId)
                        {
                            Divider()
                            
                            AsyncButton(action: {
                                try await profile.addChild(wall.roomId)
                                self.presentation.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    RoomAvatarView(room: wall, avatarText: .oneLetter)
                                        .frame(width: 100, height: 100)

                                    Text(wall.name ?? "??")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

            }
            
            Spacer()
            
            Button(role: .destructive, action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
        }
        .padding()
    }
}

