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
    @Environment(\.colorScheme) private var colorScheme
    
    var avatarText: AvatarText
    private var textColor: Color {
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
                    let color = Color.background.randomColor(from: room.roomId.stringValue)

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
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(textColor)
                                .position(x: location.x,
                                          y: location.y)
                        }
                        else {
                            Text(name)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
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
