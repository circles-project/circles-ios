//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ChannelInviteSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/11/20.
//

import SwiftUI
import Matrix

struct RoomInviteSheet: View {
    @ObservedObject var room: Matrix.Room
    var title: String? = nil
    @Environment(\.presentationMode) var presentation
    @State var newUsers: [Matrix.User] = []
    @State var newestUserIdString: String = ""
    @State var pending = false

    var inputForm: some View {
        VStack(alignment: .center) {
            
            HStack {
                Button(action: {
                    self.pending = false
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.subheadline)
                }
                //.padding()
                Spacer()
            }
            
            Text(title ?? "Invite Users to \(room.name ?? "This Room")")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()


            HStack {
                TextField("User ID", text: $newestUserIdString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)

                AsyncButton(action: {
                    guard let userId = UserId(newestUserIdString)
                    else {
                        // FIXME: Set some error message
                        return
                    }
                    let user = room.session.getUser(userId: userId)

                    await MainActor.run {
                        self.newUsers.append(user)
                        self.newestUserIdString = ""
                    }
                }) {
                    Text("Add")
                }
            }
            .disabled(pending)
            .padding()

            VStack(alignment: .leading) {
                Text("Users to Invite:")
                VStack(alignment: .leading) {
                    List {
                        ForEach(newUsers) { user in
                            MessageAuthorHeader(user: user)
                        }
                    }
                }
                //.padding(.leading)
            }
            
            Spacer()

            AsyncButton(action: {
                for user in newUsers {
                    try await room.invite(userId: user.userId)
                }

                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Send \(newUsers.count) Invitation(s)", systemImage: "envelope")
                    .padding()
                    .frame(width: 300.0, height: 40.0)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .disabled(pending || newUsers.isEmpty)
            .padding()

            Spacer()
        }
        .padding()


    }

    var body: some View {
        ZStack {
            inputForm

            if pending {
                Color.gray
                    .opacity(0.60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                ProgressView().progressViewStyle(
                    CircularProgressViewStyle(tint: .white)
                )
                .scaleEffect(2.5, anchor: .center)
            }
        }
    }

}

/*
struct ChannelInviteSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChannelInviteSheet()
    }
}
*/
