//
//  InviteToFollowMeView.swift
//  Circles
//
//  Created by Charles Wright on 5/2/24.
//

import SwiftUI
import Matrix

struct InviteToFollowMeView: View {
    var user: Matrix.User
    @Environment(\.presentationMode) var presentation
    
    @State var selected: Set<Matrix.Room> = []
    
    var body: some View {
        ScrollView {
            VStack {
                
                Text("Which of your timelines do you want \(user.displayName ?? user.userId.username) to follow?")
                    .font(.title2)
                    .padding()
                
                Text("Select one or more")
                
                CirclePicker(selected: $selected)
                    .padding()
                
                AsyncButton(action: {
                    for room in selected {
                        if room.invitedMembers.contains(user.userId) {
                            print("User \(user.userId) is already following us in circle \(room.name ?? room.roomId.stringValue)")
                        } else {
                            try await room.invite(userId: user.userId)
                        }
                    }
                }) {
                    Text("Send \(selected.count) invitation(s)")
                }
                .disabled(selected.isEmpty)
                .padding()
                
                Button(role: .destructive, action: {
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                .padding()
            }
        }
        .navigationTitle("Invite to Follow Me")
    }
}
