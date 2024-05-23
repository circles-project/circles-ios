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
    
    @State var selected: Set<CircleSpace> = []
    
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
                    for space in selected {
                        if let wall = space.wall {
                            if wall.invitedMembers.contains(user.userId) {
                                print("User \(user.userId) is already following us in circle \(space.name ?? wall.name ?? space.roomId.stringValue)")
                            } else {
                                try await wall.invite(userId: user.userId)
                            }
                        } else {
                            print("No 'wall' timeline room for circle \(space.name ?? space.roomId.stringValue)")
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
