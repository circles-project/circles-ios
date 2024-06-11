//  Copyright 2022, 2023 FUTO Holdings Inc
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
    
    @AppStorage("blurUnknownUserPicture") var blurUnknownUserPicture = true
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    @State private var blurRadius: CGFloat
    
    init(user: Matrix.User, profile: ProfileSpace) {
        self.user = user
        self.profile = profile
        
        if profile.session.ignoredUserIds.contains(user.userId) {
            self._blurRadius = State(wrappedValue: 5.0)
        } else {
            self._blurRadius = State(wrappedValue: 0.0)
        }
    }
    
    var displayName: String {
        user.displayName ?? user.userId.username
    }
    
    var status: String {
        guard let msg = user.statusMessage else {
            return ""
        }
        return "Status: \"\(msg)\""
    }
    
    var body: some View {
        HStack(alignment: .center) {
            UserAvatarView(user: user)
                .scaledToFill()
                .frame(width: 70, height:70)
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
            }
            
            Spacer()
            
            /*
            Image(systemName: "chevron.right")
                .padding(.trailing, 2)
                .foregroundColor(.gray)
            */
        }
        .blur(radius: blurUnknownUserPicture ? blurRadius : 0)
        //.padding([.leading, .top], 5)
        .contextMenu {
            if profile.joinedMembers.contains(user.userId) {
                AsyncButton(role: .destructive, action: {}) {
                    Label("Remove connection", systemImage: "person.fill.xmark")
                }
            } else {
                AsyncButton(action: {
                    do {
                        try await profile.invite(userId: user.userId)
                    } catch {
                        print("PersonHeaderRow - ERROR:\t \(error)")

                        self.alertTitle = "Request failed"
                        self.alertMessage = "An unknown error has occurred. Please try again later."
                        self.showAlert = true
                    }
                }) {
                    Label("Invite to connect", systemImage: "link")
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertTitle),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
            }
            if user.session.ignoredUserIds.contains(user.userId) {
                AsyncButton(action: {
                    try await user.session.unignoreUser(userId: user.userId)
                }) {
                    Label("Un-ignore this user", systemImage: "person.wave.2.fill")
                }
                if blurRadius > 0 {
                    Button(action: {
                        blurRadius = 0.0
                    }) {
                        Text("Remove blur")
                    }
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
