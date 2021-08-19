//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PersonsChannelRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/3/20.
//

import SwiftUI

struct PersonsDummyCircleRow: View {
    @ObservedObject var user: MatrixUser
    
    var image: Image {
        guard let img = user.avatarImage else {
            return Image(uiImage: UIImage())
        }
        return Image(uiImage: img)
    }
    
    var userName: String {
        guard let displayName = user.displayName else {
            return user.id.components(separatedBy: ":").first ?? user.id
        }
        return displayName
    }
    
    var body: some View {
        HStack(alignment: .center) {
            
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 40, height: 40)
                .clipped()

            VStack(alignment: .leading) {
                /*
                Text(userName)
                    .font(.headline)
                    .fontWeight(.semibold)
                */
                
                Text("All Circles")
                    .font(.headline)
                    .fontWeight(.semibold)

                /*
                timestamp
                    .font(.caption)
                    .foregroundColor(Color.gray)
                */
            }
            
            //Image(systemName: "chevron.right")
            
            Spacer()

        }
        .padding(.leading, 5)
    }
}

struct PersonsCircleRow: View {
    @ObservedObject var room: MatrixRoom
    var showOwners = false
    
    var image: Image {
        guard let img = room.avatarImage else {
            return Image(uiImage: UIImage())
        }
        return Image(uiImage: img)
    }
    
    var roomName: String {
        guard let displayName = room.displayName else {
            return room.id
        }
        return displayName
    }
    
    var userName: String {
        guard let user = room.creator ?? room.owners.first else {
            return "(unknown)"
        }
        guard let displayName = user.displayName else {
            return user.id.components(separatedBy: ":").first ?? user.id
        }
        return displayName
    }
    
    var timestamp: Text {
        let formatter = RelativeDateTimeFormatter()
        let ts = room.timestamp
        
        return Text("Last updated \(ts, formatter: formatter)")
    }
    
    var body: some View {
        HStack(alignment: .center) {
            let frameSize: CGFloat = showOwners ? 60 : 40
            
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: frameSize, height: frameSize)
                .clipped()

            VStack(alignment: .leading) {
                if showOwners {
                    Text(userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(roomName)
                    .font(.headline)
                    .fontWeight(.semibold)

                /*
                Text(room.id)
                    .font(.caption)
                    .foregroundColor(Color.gray)
                */

                timestamp
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }
            
            //Image(systemName: "chevron.right")
            
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
