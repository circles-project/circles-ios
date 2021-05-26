//
//  ScreenOverviewCard.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 11/5/20.
//

import SwiftUI


struct CircleOverviewCard: View {
    @ObservedObject var circle: SocialCircle
    
    var timestamp: Text {
        let formatter = RelativeDateTimeFormatter()
        
        guard let ts = circle.stream.timestamp else {
            return Text("")
        }
        
        return Text("Last updated \(ts, formatter: formatter)")
    }
    
    var avatar: some View {
        CircleAvatar(socialcircle: circle)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                
                avatar
                    .frame(width: 120, height: 120)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(circle.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                    Text("Following \(circle.stream.rooms.count)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)

                    Text("Followed by \(circle.followers.count)")
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
