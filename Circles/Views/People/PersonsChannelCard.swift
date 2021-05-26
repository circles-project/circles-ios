//
//  PersonsChannelCard.swift
//  Kombucha Social
//
//  Created by Macro Ramius on 12/3/20.
//

import SwiftUI

struct PersonsChannelCard: View {
    @ObservedObject var room: MatrixRoom
    
    var image: Image {
        guard let img = room.avatarImage else {
            return Image(uiImage: UIImage())
        }
        return Image(uiImage: img)
    }
    
    var name: String {
        guard let displayName = room.displayName else {
            return room.id
        }
        return displayName
    }
    
    var timestamp: Text {
        let formatter = RelativeDateTimeFormatter()
        let ts = room.timestamp
        
        return Text("Last updated \(ts, formatter: formatter)")
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            let cardSize: CGFloat = 75
            
            image
                .resizable()
                .scaledToFill()
                .frame(width: cardSize, height: cardSize)
                //.clipped()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                .shadow(radius: 5)
                .padding(5)
                
            if room.avatarImage == nil {
                Circle()
                    .foregroundColor(Color.gray)
                    .opacity(0.80)
                    .frame(width: cardSize, height: cardSize)

            }

            VStack(alignment: .center) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3)

                /*
                timestamp
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3)
                */
            }
            .frame(width: cardSize, height: cardSize)
            
            //Image(systemName: "chevron.right")
            
            //Spacer()

        }
        .padding([.leading, .top], 5)
    }
}

/*
struct PersonsChannelCard_Previews: PreviewProvider {
    static var previews: some View {
        PersonsChannelCard()
    }
}
*/
