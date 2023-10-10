//
//  KnockingUserCard.swift
//  Circles
//
//  Created by Charles Wright on 10/10/23.
//

import SwiftUI
import Matrix

struct KnockingUserCard: View {
    @ObservedObject var user: Matrix.User
    @ObservedObject var room: Matrix.Room
    @State var showRejectDialog: Bool = false
    
    var reason: String? {
        if let event = room.state[M_ROOM_MEMBER]?[user.userId.stringValue],
           let content = event.content as? RoomMemberContent,
           content.membership == .knock
        {
            return content.reason
        } else {
            return "Foo bar baz.  Just because."
        }
    }
    
    @ViewBuilder
    var rejectButton: some View {
        Button(role: .destructive, action: {
            self.showRejectDialog = true
        }) {
            Label("Reject", systemImage: "hand.thumbsdown.fill")
        }
        .buttonStyle(.bordered)
        .confirmationDialog("Reject request for invite",
                            isPresented: $showRejectDialog,
                            actions: {
                                if let event = room.state[M_ROOM_MEMBER]?[user.userId.stringValue] {
                                    AsyncButton(role: .destructive, action: {
                                        print("Rejecting knock from user \(user.userId.stringValue) with ban and reporting as spam")
                                        try await room.ban(userId: user.userId, reason: "spam")
                                        try await room.session.sendReport(for: event.eventId, in: room.roomId, score: 50, reason: "spam")
                                    }) {
                                        Label("Report spam", systemImage: "xmark.bin.fill")
                                    }
                                }
            
                                AsyncButton(role: .destructive, action: {
                                    print("Rejecting knock from user \(user.userId.stringValue) with ban")
                                    try await room.ban(userId: user.userId)
                                }) {
                                    Label("Reject and block this user", systemImage: "person.fill.xmark")
                                }
            
                                AsyncButton(role: .destructive, action: {
                                    print("Rejecting knock from user \(user.userId.stringValue) with kick")
                                    try await room.kick(userId: user.userId)
                                }) {
                                    Label("Reject request", systemImage: "person.fill.xmark")
                                }
                            }
        )
    }
    
    @ViewBuilder
    var acceptButton: some View {
        AsyncButton(action: {
            print("Accepting knock from \(user.userId.stringValue)")
            try await room.invite(userId: user.userId)
        }) {
            Label("Accept", systemImage: "hand.thumbsup.fill")
        }
        .buttonStyle(.bordered)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                ProfileImageView(user: user)
                    .frame(width: 110, height: 110)
                
                VStack(alignment: .leading) {
                    Text(user.displayName ?? user.userId.username)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(user.userId.stringValue)
                        .foregroundColor(.gray)
                    
                    Text("Common connections with you:")
                    VStack(alignment: .leading) {
                        Text("In \(Int.random(in: 2...10)) of your groups")
                        
                        Text("Following \(Int.random(in: 2...10)) of your friends' timelines")
                        
                        Text("Connected to \(Int.random(in: 2...10)) of your people")
                    }
                    .foregroundColor(.gray)
                    .padding(.leading)

                }
            }
            
            if let reason = reason {
                VStack(alignment: .leading) {
                    Text("Message:")
                    Text(reason)
                        .lineLimit(3)
                        .padding(.leading)
                        //.font(.subheadline)
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                }
                .padding()
            }
                
            HStack(alignment: .center, spacing: 20) {
                Spacer()
                
                rejectButton
                                    
                acceptButton
                
                Spacer()
            }
        }
    }
}

