//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  GroupOverviewRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 7/29/20.
//

import SwiftUI
import Matrix

struct GroupOverviewRow: View {
    @ObservedObject var room: Matrix.Room
    
    var timestamp: some View {
        let formatter = RelativeDateTimeFormatter()
        if let date = room.latestMessage?.timestamp {
            return Text("Last updated \(date, formatter: formatter)")
        } else {
            return Text("")
        }
    }
    
    
    var body: some View {
        HStack(alignment: .top) {

            /*
            Image(uiImage: room.avatar ?? UIImage())
                .renderingMode(.original)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                //.clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.gray)
                .padding(.all, 2)
                .onAppear {
                    room.updateAvatarImage()
                }
             */
            RoomAvatar(room: room)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                /*
                .onAppear {
                    // Dirty nasty hack to test how/when SwiftUI is updating our Views
                    Task {
                        while true {
                            let sec = Int.random(in: 10...30)
                            try await Task.sleep(for: .seconds(sec))
                            let imageName = ["diamond.fill", "circle.fill", "square.fill", "seal.fill", "shield.fill"].randomElement()!
                            let newImage = UIImage(systemName: imageName)
                            await MainActor.run {
                                print("Setting avatar for room \(room.roomId)")
                                room.avatar = newImage
                            }
                        }
                    }
                }
                */
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 3) {
                    Text(room.name ?? room.id)
                        .fontWeight(.bold)
                    Spacer()
                }
                .font(.title2)

                VStack(alignment: .leading) {
                    Text("\(room.joinedMembers.count) members")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Topic: \(room.topic ?? "none")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    timestamp
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(room.roomId.description)
                        .font(.subheadline)
                        .foregroundColor(.red)
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
