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
        case oneLetter
        case roomName
        case roomInitials
    }
    
    var text: String? {
        if let name = room.name {
            switch avatarText {
            case .none:
                return nil
            case .oneLetter:
                return name.first?.uppercased() ?? ""
            case .roomName:
                return name
            case .roomInitials:
                return name.split(whereSeparator: { $0.isWhitespace })
                           .compactMap({ $0.first?.uppercased() })
                           .joined()
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        if let img = room.avatar {
            Image(uiImage: img)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
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
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .onAppear {
                            // Fetch the avatar from the url
                            room.updateAvatarImage()
                        }
                        //.padding(3)

                    if avatarText != .none,
                       let text = self.text {
                        Text(text)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .gray, radius: 3)
                    }

                }
            }
        }
    }
}
