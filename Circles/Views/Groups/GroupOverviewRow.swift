//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupOverviewRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 7/29/20.
//

import SwiftUI
import MatrixSDK

struct GroupOverviewRow: View {
    @ObservedObject var room: MatrixRoom
    
    var timestamp: some View {
        let formatter = RelativeDateTimeFormatter()
        
        return Text("Last updated \(room.timestamp, formatter: formatter)")
    }
    
    var shield: some View {
        VStack(alignment: .leading) {
            if room.isEncrypted {
                Image(systemName: "lock.shield")
                    .foregroundColor(Color.accentColor)
            }
            else {
                Image(systemName: "xmark.shield")
                    .foregroundColor(Color.red)
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {

            Image(uiImage: room.avatarImage ?? UIImage())
                .renderingMode(.original)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                //.clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.gray)
                .padding(.all, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 3) {
                    shield
                    Text(room.displayName ?? room.id)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.title2)

                VStack(alignment: .leading) {
                    Text("\(room.membersCount) members")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Topic: \(room.topic ?? "none")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    timestamp
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)
            }
            .padding(.top, 5)
        }
    }
}

/*
struct ChannelOverviewRow_Previews: PreviewProvider {
    static var previews: some View {
        ChannelOverviewRow()
    }
}
 */
