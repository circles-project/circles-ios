//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PersonsChannelRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/3/20.
//

import SwiftUI
import Matrix

struct PersonsCircleRow: View {
    @ObservedObject var room: Matrix.SpaceChildRoom
    @ObservedObject var user: Matrix.User
    
    init(room: Matrix.SpaceChildRoom) {
        self.room = room
        self.user = room.session.getUser(userId: room.creator)
    }
    
    var roomName: String {
        room.name ?? ""
    }
    
    var userName: String {
        return user.displayName ?? "\(user.userId)"
    }
    
    var body: some View {
        HStack(alignment: .center) {
            let frameSize: CGFloat = 40
            
            RoomAvatarView(room: room, avatarText: .none)
                .frame(width: frameSize, height: frameSize)
                .clipped()

            VStack(alignment: .leading) {
                
                Text(roomName)
                    .font(.headline)
                    .fontWeight(.semibold)

                /*
                Text(room.id)
                    .font(.caption)
                    .foregroundColor(Color.gray)
                */

            }
            
            //Image(systemName: SystemImages.chevronRight.rawValue)
            
            Spacer()

        }
        .padding(.leading, 5)
    }
}

/*
struct PersonsChannelRow_Previews: PreviewProvider {
    static var previews: some View {
        PersonsChannelRow()
    }
}
*/
