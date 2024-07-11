//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleOverviewCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import SwiftUI
import Matrix

struct CircleOverviewCard: View {
    @ObservedObject var room: Matrix.Room

    var formatter: RelativeDateTimeFormatter
    
    init(room: Matrix.Room) {
        self.room = room
        self.formatter = RelativeDateTimeFormatter()
        self.formatter.dateTimeStyle = .named
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                //CircleAvatar(space: space)
                RoomAvatarView(room: room, avatarText: .oneLetter)
                    .clipShape(Circle())
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(room.name ?? "(unnamed circle)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading) {
                                                
                        Text("\(room.joinedMembers.count-1) followers")

                        if room.unread > 0 {
                            Text("\(room.unread) unread posts")
                                .fontWeight(.bold)
                        } else {
                            let age = Date().timeIntervalSince(room.timestamp)
                            if age < 2 * 60.0 {
                                Text("Updated just now")
                            } else {
                                Text("Last updated \(room.timestamp, formatter: formatter)")
                            }
                        }
                        

                        let knockCount = room.knockingMembers.count
                        if knockCount > 0 {
                            let color = Color(light: .blue, dark: .white)
                            Label("\(knockCount) requests for invitations", systemImage: "star.fill")
                                .foregroundColor(color)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }
                //.padding(.leading)

                Spacer()
            }
        }
    }
}

/*
struct ScreenOverviewCard_Previews: PreviewProvider {
    static var previews: some View {
        ScreenOverviewCard()
    }
}
 */
