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
                
                CircleAvatar(space: space)
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(space.name ?? "(unnamed circle)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading) {
                        
                        Text("Following \(space.following.count)")
                        
                        Text("Followed by \(space.followers.count)")

                        if space.unread > 0 {
                            Text("\(space.unread) unread posts")
                                .fontWeight(.bold)
                        } else {
                            Text("Last updated \(space.timestamp, formatter: formatter)")
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
                    .font(.body)
                    .foregroundColor(.gray)
                }
                .padding(.leading)

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
