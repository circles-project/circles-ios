//
//  UsersToInviteView.swift
//  Circles
//
//  Created by Charles Wright on 11/20/23.
//

import SwiftUI
import Matrix

struct UsersToInviteView: View {
    var session: Matrix.Session
    var room: Matrix.Room?
    
    @Binding var users: [Matrix.User]
    
    @FocusState var searchFocused

    @State var newestUserIdString: String = ""
    @State var pending = false
    @State var suggestions = [UserId]()
    @State var searchTask: Task<Void,Swift.Error>?
    
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    @State var showConfirmAutocorrect = false
    @State var suggestedUserId: UserId?
    
    
    @ViewBuilder
    var searchField: some View {
        TextField("User ID", text: $newestUserIdString)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .onChange(of: newestUserIdString) { searchTerm in
                self.searchTask = self.searchTask ?? Task {
                    let currentUserIds = self.users.map { $0.userId }
                    let suggestedUserIds = try await session.searchUserDirectory(term: searchTerm)
                        .filter {
                            if currentUserIds.contains($0) { return false }
                            
                            if let room = self.room {
                                if room.joinedMembers.contains($0) { return false }
                                if room.invitedMembers.contains($0) { return false }
                                if room.bannedMembers.contains($0) { return false }
                            }
                            
                            return true
                        }
                    print("INVITE:\tGot \(suggestedUserIds.count) search results: \(suggestedUserIds)")
                    await MainActor.run {
                        self.suggestions = suggestedUserIds
                        self.searchTask = nil
                    }
                }
            }
            .focused($searchFocused)
            .frame(maxWidth: 300)
    }
    
    @ViewBuilder
    var addButton: some View {
        Button(action: {
            guard let userId = UserId(newestUserIdString)
            else {
                if let suggestion = UserId.autoCorrect(newestUserIdString, domain: session.creds.userId.domain) {
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
            if let room = self.room {
                if room.joinedMembers.contains(userId) {
                    self.alertTitle = "\(userId) is already a member of this room"
                    self.alertMessage = ""
                    self.showAlert = true
                    print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                    return
                }
                else if room.bannedMembers.contains(userId) {
                    self.alertTitle = "\(userId) is banned from this room"
                    self.alertMessage = "You must unblock \(userId) before you can invite the user back to the room."
                    self.showAlert = true
                    print("RoomInviteSheet - ERROR:\t \(self.alertMessage)")
                    return
                }
            }

            let user = session.getUser(userId: userId)
            if !self.users.contains(user) {
                print("RoomInviteSheet - INFO:\t Adding \(userId) to invite list")
                self.users.append(user)
            }
            self.newestUserIdString = ""
            self.searchFocused = false
            
        }) {
            Text("Add")
        }
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
                        let user = session.getUser(userId: userId)
                        self.users.append(user)
                        self.newestUserIdString = ""
                        self.suggestedUserId = nil
                        self.searchFocused = false
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
    }
    
    @ViewBuilder
    var currentList: some View {
        VStack(alignment: .leading) {
            Text("USERS TO INVITE")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            let columns = [
                GridItem(.adaptive(minimum: 150))
            ]
            
            LazyVGrid(columns: columns) {
                
                ForEach(users) { user in
                    Button(action: {
                        let userId = user.userId
                        self.users.removeAll(where: {$0.userId == userId})
                    }) {
                        Label(user.userId.stringValue, systemImage: "xmark")
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.gray)
                }
            }
            .padding(.bottom)
        }
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    searchField
                    addButton
                }
                
                if searchFocused && !self.suggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions) { userId in
                                let user = session.getUser(userId: userId)
                                //Text("User \(userId.description)")
                                Button(action: {
                                    self.newestUserIdString = ""
                                    self.suggestions = []
                                    self.users.append(user)
                                    self.searchFocused = false
                                }) {
                                    MessageAuthorHeader(user: user)
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(0.9)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .padding(.bottom)
                    .padding(.leading)
                    //Divider()
                }
                
                Spacer()
                
                if !searchFocused {
                    currentList
                }
            }
            .padding(.leading)
            
    }
}

