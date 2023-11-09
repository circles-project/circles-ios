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
    @State var suggestions = [UserId]()
    @State var searchTask: Task<Void,Swift.Error>?

    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false

    @State var showConfirmAutocorrect = false
    @State var suggestedUserId: UserId?
    
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
                .font(.title3)
                .fontWeight(.bold)

            Spacer()


            HStack {
                TextField("User ID", text: $newestUserIdString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: newestUserIdString) { searchTerm in
                        self.searchTask = self.searchTask ?? Task {
                            let currentUserIds = self.newUsers.map { $0.userId }
                            let suggestedUserIds = try await room.session.searchUserDirectory(term: searchTerm)
                                .filter {
                                    !currentUserIds.contains($0) &&
                                    !room.joinedMembers.contains($0) &&
                                    !room.invitedMembers.contains($0) &&
                                    !room.bannedMembers.contains($0)
                                }
                            print("INVITE:\tGot \(suggestedUserIds.count) search results: \(suggestedUserIds)")
                            await MainActor.run {
                                self.suggestions = suggestedUserIds
                                self.searchTask = nil
                            }
                        }
                    }
                    .frame(maxWidth: 300)

                Button(action: {
                    guard let userId = UserId(newestUserIdString)
                    else {
                        if let suggestion = UserId.autoCorrect(newestUserIdString, domain: room.session.creds.userId.domain) {
                            self.showConfirmAutocorrect = true
                            self.suggestedUserId = suggestion
                        } else {
                            self.alertTitle = "Invalid User ID"
                            self.alertMessage = "Circles user ID's should start with an @ and have a domain at the end, like @username:example.com"
                            self.showAlert = true
                            print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                        }
                        return
                    }
                    if room.joinedMembers.contains(userId) {
                        self.alertTitle = "\(userId) is already a member of this room"
                        self.alertMessage = ""
                        self.showAlert = true
                        print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                        return
                    }
                    /* // cvw: Removing this check because Matrix kinda sucks at invitations and users may legitimately need to re-send one from time to time
                    else if room.invitedMembers.contains(userId) {
                        self.alertTitle = "\(userId) has already been invited to this room"
                        self.alertMessage = "\(userId) invite is still pending user decision."
                        self.showAlert = true
                        print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                        return
                    }
                    */
                    else if room.bannedMembers.contains(userId) {
                        self.alertTitle = "\(userId) is banned from this room"
                        self.alertMessage = "You must unblock \(userId) before you can invite the user back to the room."
                        self.showAlert = true
                        print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                        return
                    }

                    print("RoomInviteSheet - INFO:\t Adding \(userId) to invite list")
                    let user = room.session.getUser(userId: userId)

                    self.newUsers.append(user)
                    self.newestUserIdString = ""
                }) {
                    Text("Add")
                }
            }
            .disabled(pending)
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
            .confirmationDialog(
                "It looks like you may have mis-typed the user id",
                isPresented: $showConfirmAutocorrect,
                actions: {
                    if let userId = self.suggestedUserId {
                        Button(action: {
                            let user = room.session.getUser(userId: userId)
                            self.newUsers.append(user)
                            self.newestUserIdString = ""
                            self.suggestedUserId = nil
                        }) {
                            Text("Add \(userId.stringValue)")
                        }
                    }
                    
                    Button(role: .cancel, action: {
                        self.suggestedUserId = nil
                    }) {
                        Text("No, let me try that again")
                    }
                },
                message: {
                    if let userId = self.suggestedUserId {
                        Text("Did you mean \(userId.stringValue)?")
                    } else {
                        Text("It looks like you may have mis-typed that user id")
                    }
                }
            )
            
            if !self.suggestions.isEmpty {
                List {
                    Section(header: Text("Search Suggestions")) {
                        ForEach(suggestions) { userId in
                            let user = room.session.getUser(userId: userId)
                            //Text("User \(userId.description)")
                            Button(action: {
                                self.newestUserIdString = ""
                                self.suggestions = []
                                self.newUsers.append(user)
                            }) {
                                MessageAuthorHeader(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            

            VStack(alignment: .leading) {
                List {
                    Section(header: Text("Users to Invite:")) {
                        ForEach(newUsers) { user in
                            HStack {
                                MessageAuthorHeader(user: user)
                                Spacer()
                                Button(action: {
                                    let userId = user.userId
                                    self.newUsers.removeAll(where: {$0.userId == userId})
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            //.padding(.leading)
            
            Spacer()

            AsyncButton(action: {
                for user in newUsers {
                    try await room.invite(userId: user.userId)
                }

                self.presentation.wrappedValue.dismiss()
            }) {
                Label("Send \(newUsers.count) Invitation(s)", systemImage: "paperplane")
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
