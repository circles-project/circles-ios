//
//  RoomAvatar.swift
//  Circles
//
//  Created by Charles Wright on 4/11/23.
//

import Foundation
import SwiftUI

import Matrix

struct RoomAvatarView<Room>: View where Room: BasicRoomProtocol {
    @ObservedObject var room: Room
    @Environment(\.colorScheme) var colorScheme
    
    var avatarText: AvatarText
    var textColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    enum AvatarText: String {
        case none
        case roomName
        case roomInitials
    }
    
    var body: some View {
        if let img = room.avatar {
            Image(uiImage: img)
                .renderingMode(.original)
                .resizable()
                .scaledToFill()
                //.clipShape(RoundedRectangle(cornerRadius: 6))
                .onAppear {
                    // Fetch the avatar from the url
                    room.updateAvatarImage()
                }
                //.padding(3)
        }
        else {
            GeometryReader { geometry in
                ZStack {
                    // Make the color choice pseudo-random, but fixed based on
                    // the room name instead of changing the color randomly
                    // each time the avatar is rendered.
                    let colorChoice: Int = room.roomId.stringValue.chars.reduce(0, { acc, str in
                        guard let asciiValue = Character(str).asciiValue
                        else {
                            return acc
                        }

                        return acc + Int(asciiValue)
                    })
                    let colors = [Color.blue, Color.purple, Color.orange, Color.yellow, Color.red, Color.pink, Color.green]
                    let color = colors[colorChoice % colors.count]

                    RoundedRectangle(cornerSize: CGSize())
                        .foregroundColor(color)
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onAppear {
                            // Fetch the avatar from the url
                            room.updateAvatarImage()
                        }
                        //.padding(3)

                    if avatarText != .none,
                       let name = room.name {
                        if avatarText == .roomInitials {
                            let location = CGPoint(x: 0.5 * geometry.size.width, y: 0.5 * geometry.size.height)
                            let initials = name.split(whereSeparator: { $0.isWhitespace })
                                               .compactMap({ $0.first?.uppercased() })
                                               .joined()
                            
                            Text(initials)
                                .fontWeight(.bold)
                                .foregroundColor(textColor)
                                .position(x: location.x,
                                          y: location.y)
                        }
                        else {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 5)
                        }
                    }
                }
            }
        }
    }
}
