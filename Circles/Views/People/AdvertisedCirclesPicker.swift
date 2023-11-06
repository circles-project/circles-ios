//
//  AdvertisedCirclesPicker.swift
//  Circles
//
//  Created by Charles Wright on 11/6/23.
//

import SwiftUI
import Matrix

struct AdvertisedCirclesPicker: View {
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
                    
                    let advertisedRoomIds = profile.rooms.compactMap({$0.roomId})
                    
                    ForEach(circles.rooms) { space in
                        if let wall = space.wall,
                           !advertisedRoomIds.contains(wall.roomId)
                        {
                            Divider()
                            
                            AsyncButton(action: {
                                try await profile.addChildRoom(wall.roomId)
                                self.presentation.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    RoomAvatar(room: wall, avatarText: .roomInitials)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())

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

