//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  PersonHeaderRow.swift
//  Circles for iOS
//
//  Created by Charles Wright on 12/3/20.
//

import SwiftUI
import Matrix

struct PersonHeaderRow: View {
    @ObservedObject var user: Matrix.User
    var profile: ProfileSpace
    
    var image: Image {
        guard let img = user.avatar else {
            return Image(systemName: "person.crop.square")
        }
        
        return Image(uiImage: img)
    }
    
    var displayName: String {
        guard let name = user.displayName else {
            return user.id.components(separatedBy: ":").first ?? user.id
        }
        return name
    }
    
    var status: String {
        guard let msg = user.statusMessage else {
            return ""
        }
        return "Status: \"\(msg)\""
    }
    
    var body: some View {
        HStack(alignment: .center) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 70, height:70)
                //.clipped()
                //.clipShape(Circle())
                .clipShape(RoundedRectangle(cornerRadius: 7))

            
            VStack(alignment: .leading) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(user.id)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                
                Text(status)
                    .font(.headline)
                    .fontWeight(.regular)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .padding(.trailing, 2)
                .foregroundColor(.gray)
        }
        //.padding([.leading, .top], 5)
        .contextMenu {
            if profile.joinedMembers.contains(user.userId) {
                AsyncButton(role: .destructive, action: {}) {
                    Label("Remove connection", systemImage: "person.fill.xmark")
                }
            } else {
                AsyncButton(action: {}) {
                    Label("Invite to connect", systemImage: "link")
                }
            }
            if user.session.ignoredUserIds.contains(user.userId) {
                AsyncButton(action: {
                    try await user.session.unignoreUser(userId: user.userId)
                }) {
                    Label("Un-ignore this user", systemImage: "person.wave.2.fill")
                }
            } else {
                AsyncButton(action: {
                    try await user.session.ignoreUser(userId: user.userId)
                }) {
                    Label("Ignore this user", systemImage: "person.2.slash.fill")
                }
            }
        }
    }
}

/*
struct PersonHeaderRow_Previews: PreviewProvider {
    static var previews: some View {
        PersonHeaderRow()
    }
}
*/
