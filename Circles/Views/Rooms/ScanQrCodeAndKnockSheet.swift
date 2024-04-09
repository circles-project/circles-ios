//
//  ScanQrCodeAndKnockView.swift
//  Circles
//
//  Created by Charles Wright on 10/11/23.
//

import SwiftUI
import Matrix

struct ScanQrCodeAndKnockSheet: View {
    var session: Matrix.Session
    @State var reason: String = ""
    @State var roomId: RoomId? = nil
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var app: CirclesApplicationSession
    
    var body: some View {
        VStack {
            if let roomId = roomId {
                if let room = session.invitations[roomId] {
                    
                    Text("You have an invitation already!")
                    
                    Spacer()
                    
                    let user = session.getUser(userId: room.sender)
                    switch room.type {
                    case ROOM_TYPE_CIRCLE:
                        InvitedCircleCard(room: room, user: user, container: app.circles)
                    case ROOM_TYPE_GROUP:
                        InvitedGroupCard(room: room, user: user, container: app.groups)
                    case ROOM_TYPE_PHOTOS:
                        GalleryInviteCard(room: room, user: user, container: app.galleries)
                    default:
                        EmptyView()
                    }
                    
                    Spacer()
                    
                } else {
                    KnockOnRoomView(roomId: roomId, session: session)
                }
            } else {
                ScanQrCodeView(roomId: $roomId)
            }
            
            Button(role: .destructive, action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .padding()
            }
        }
        .padding()
    }
}
