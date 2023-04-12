//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  CircleAvatar.swift
//  Circles for iOS
//
//  Created by Charles Wright on 1/27/21.
//

import SwiftUI
import Matrix

struct RoomCircleAvatar: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.colorScheme) var colorScheme
    //var position: CGPoint
    var location: CGPoint
    var scale: CGFloat

    var outlineColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    var body: some View {
        GeometryReader { geometry in
            //let xCenter = 0.5 * geometry.size.width
            //let yCenter = 0.5 * geometry.size.height
            //let scale: CGFloat = 0.6
            
            ZStack {

                if let img = room.avatar {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: scale * geometry.size.width,
                               height: scale * geometry.size.height)
                        .clipShape(
                            //RoundedRectangle(cornerRadius: 10)
                            Circle()
                        )
                        .position(x: location.x,
                                  y: location.y)
                }
                else {
                    let color = [Color.blue, Color.purple, Color.orange, Color.yellow, Color.red, Color.pink, Color.green].randomElement() ?? Color.green
                    let userId = room.creator
                    let user = room.session.getUser(userId: userId)
                    
                    Circle()
                        .foregroundColor(color)
                        .scaleEffect(scale)
                        .position(x: location.x,
                                  y: location.y)
                        .onAppear {
                            room.updateAvatarImage()
                        }
                    
                    if let displayName = user.displayName {
                        let initials = displayName.split(whereSeparator: { $0.isWhitespace }).joined().capitalized
                        Text(initials)
                            .fontWeight(.bold)
                            .foregroundColor(outlineColor)
                            .position(x: location.x,
                                      y: location.y)
                    }
                }

                

                Circle()
                    .stroke(outlineColor, lineWidth: 2.0)
                    .scaleEffect(scale)
                    .position(x: location.x,
                              y: location.y)

                
            }
        }
    }
}

struct CircleAvatar: View {
    @ObservedObject var space: CircleSpace
    @Environment(\.colorScheme) var colorScheme

    var outlineColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color.black
    }
    
    var body: some View {
        let mainRoom: Matrix.Room? = space.rooms.first {
            $0.creator == space.session.creds.userId
        }
        let otherRooms = space.rooms.filter {
            $0.creator != space.session.creds.userId
        }
        let N_MAX = 9
        let n = min(otherRooms.count, N_MAX)
        let secondaryRooms = otherRooms.sample(UInt(n))
        //let positions = (0 ..< N_MAX+1).sample(UInt(n))
        
        GeometryReader { geometry in
            let mainCircleScale = CGFloat(0.7)
            let smallCircleScale = CGFloat(0.3)
            let len = min(geometry.size.height, geometry.size.width)
            let radius = mainCircleScale * len * 0.5
            let midpointX = 0.5 * geometry.size.width
            let midpointY = 0.5 * geometry.size.height
            let midpoint = CGPoint(x: midpointX, y: midpointY)
            let startAngle = Double.random(in: 5.0 ..< 85.0)

            //ZStack {

            if let myRoom = mainRoom {
                
                RoomCircleAvatar(room: myRoom,
                                 location: midpoint,
                                 scale: mainCircleScale)
                /*
                Circle()
                    .stroke(Color.red, lineWidth: 2.0)
                    .position(x: midpointX, y: midpointY)
                    .scaleEffect(mainCircleScale)
                */
            }
            else {
                Circle()
                    .stroke(outlineColor, lineWidth: 2.0)
                    .position(x: midpointX, y: midpointY)
                    .scaleEffect(mainCircleScale)
            }
            
            ForEach(0 ..< n) { i in
                let theirRoom = secondaryRooms[i]
                //let p = positions[i]
                let p = i
                let fraction: Double = Double(p) / Double(n)
                let maxAngle = (360.0 / Double(n)) / 3.0 // Dividing by two would give us half the angle between two positions.  We want to limit this even further, hence the 3.
                let offsetAngle = Double.random(in: -maxAngle ..< maxAngle)
                //let offsetAngle = 0.0
                let angle = Angle(degrees: 360 * fraction + startAngle + offsetAngle)
                let radians = CGFloat(angle.radians)

                //let rand = CGFloat(0.3)
                let offset = (1.0 + 0.4 * smallCircleScale) * radius
                let x = midpointX + cos(radians) * offset
                let y = midpointY + sin(radians) * offset
                
                //if room.avatarImage != nil {
                    RoomCircleAvatar(room: theirRoom,
                                     location: CGPoint(x: x, y:y),
                                     scale: smallCircleScale)
                /*
                }
                else {
                    let color = [Color.blue, Color.purple, Color.orange, Color.yellow, Color.red, Color.pink, Color.green].randomElement() ?? Color.green
                    Circle()
                        .foregroundColor(color)
                        .scaleEffect(smallCircleScale)
                        .position(x: x, y: y)
                }
                */
                
            }
            

            
            //}
        }
    }
}

/*
struct CircleAvatar_Previews: PreviewProvider {
    static var previews: some View {
        CircleAvatar()
    }
}
*/
