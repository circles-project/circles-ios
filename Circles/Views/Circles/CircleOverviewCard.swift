//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleOverviewCard.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/5/20.
//

import SwiftUI


struct CircleOverviewCard: View {
    @ObservedObject var space: CircleSpace

    var formatter: RelativeDateTimeFormatter
    
    init(space: CircleSpace) {
        self.space = space
        self.formatter = RelativeDateTimeFormatter()
        self.formatter.dateTimeStyle = .named
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                //CircleAvatar(space: space)
                RoomAvatarView(room: space.wall ?? space, avatarText: .oneLetter)
                    .clipShape(Circle())
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(space.name ?? "(unnamed circle)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading) {
                        
                        Text("Following \(space.following.count)")
                        
                        Text("Followed by \(space.followers.count)")

                        if space.unread > 0 {
                            Text("\(space.unread) unread posts")
                                .fontWeight(.bold)
                        } else {
                            let age = Date().timeIntervalSince(space.timestamp)
                            if age < 2 * 60.0 {
                                Text("Updated just now")
                            } else {
                                Text("Last updated \(space.timestamp, formatter: formatter)")
                            }
                        }
                        
                        if let wall = space.wall {
                            let knockCount = wall.knockingMembers.count
                            if knockCount > 0 {
                                let color = Color(light: .blue, dark: .white)
                                Label("\(knockCount) requests for invitations", systemImage: "star.fill")
                                    .foregroundColor(color)
                            }
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
