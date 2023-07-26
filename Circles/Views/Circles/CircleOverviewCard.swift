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
    
    var timestamp: Text {
        let formatter = RelativeDateTimeFormatter()
        
        guard let ts = space.timestamp else {
            return Text("")
        }
        
        return Text("Last updated \(ts, formatter: formatter)")
    }
    
    var avatar: some View {
        CircleAvatar(space: space)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                
                avatar
                    .frame(width: 120, height: 120)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(space.name ?? "(unnamed circle)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    Text("Following \(space.following.count)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)

                    Text("Followed by \(space.followers.count)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)

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
