//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ChannelInviteSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/11/20.
//

import SwiftUI

struct RoomInviteSheet: View {
    @ObservedObject var room: MatrixRoom
    var title: String? = nil
    @Environment(\.presentationMode) var presentation
    @State var newUserIds: [String] = []
    @State var newestUserId: String = ""
    @State var pending = false

    var inputForm: some View {
        VStack(alignment: .center) {
            Text(title ?? "Invite New Followers to \(room.displayName ?? room.id)")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()


            HStack {
                TextField("User ID", text: $newestUserId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)

                Button(action: {
                    if let canonicalUserId = room.matrix.canonicalizeUserId(userId: newestUserId) {
                        self.newUserIds.append(canonicalUserId)
                    }
                    self.newestUserId = ""
                }) {
                    Text("Add")
                }
            }
            .disabled(pending)
            .padding()

            VStack(alignment: .leading) {
                Text("Users to Invite:")
                VStack(alignment: .leading) {
                    /*
                    if newUserIds.isEmpty {
                        Text("(none)")
                    }
                    else {
 */
                        List {
                            ForEach(newUserIds, id: \.self) { userId in
                                if let user = room.matrix.getUser(userId: userId) {
                                    MessageAuthorHeader(user: user)
                                }
                                else {
                                    //Text(userId)
                                    DummyMessageAuthorHeader(userId: userId)
                                }
                            }
                            .onDelete(perform: { indexSet in
                                self.newUserIds.remove(atOffsets: indexSet)
                            })
                        }
                    //}
                }
                .padding(.leading)


            }

            Button(action: {
                let dgroup = DispatchGroup()
                var errors: KSError? = nil

                self.pending = true

                for userId in newUserIds {
                    dgroup.enter()
                    room.invite(userId: userId) { response in
                        print("Got invite response")
                        switch(response) {
                        case .failure(let error):
                            let msg = "Failed to send invitation: \(error)"
                            print(msg)
                            errors = errors ?? KSError(message: msg)
                        case .success:
                            print("Successfully invited \(userId) to \(room.id)")
                        }
                        dgroup.leave()
                    }
                }

                dgroup.notify(queue: .main) {
                    self.pending = false
                    guard let err = errors else {
                        self.presentation.wrappedValue.dismiss()
                        return
                    }

                    print("Invite(s) failed: \(err)")

                }
            }) {
                Label("Send Invitation(s)", systemImage: "envelope")
            }
            .disabled(pending)
            .padding()

            Spacer()


            Button(action: {
                self.pending = false
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            //.padding()
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
