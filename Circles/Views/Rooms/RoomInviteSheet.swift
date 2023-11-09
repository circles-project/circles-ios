//  Copyright 2020, 2021 Kombucha Digital Privacy Systems LLC
//
//  ChannelInviteSheet.swift
//  Circles for iOS
//
//  Created by Charles Wright on 11/11/20.
//

import SwiftUI
import Combine
import Matrix

struct RoomInviteSheet: View {
    @ObservedObject var room: Matrix.Room
    var title: String? = nil
    @Environment(\.presentationMode) var presentation
    
    @FocusState var searchFocused
    @State var showingKeyboard = false
        
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
    
    @ViewBuilder
    var searchField: some View {
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
            .focused($searchFocused)
            .frame(maxWidth: 300)
    }
    
    @ViewBuilder
    var addButton: some View {
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

            let user = room.session.getUser(userId: userId)
            if !self.newUsers.contains(user) {
                print("RoomInviteSheet - INFO:\t Adding \(userId) to invite list")
                self.newUsers.append(user)
            }
            self.newestUserIdString = ""
            self.searchFocused = false
            
        }) {
            Text("Add")
        }
        .disabled(pending)
        //.padding()
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
    
    // Inspired by https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
    private var keyboardPublisher: AnyPublisher<CGFloat,Never> {
        Publishers.Merge(
            NotificationCenter.default
                              .publisher(for: UIResponder.keyboardWillShowNotification)
                              .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                              .map { $0.height },
            NotificationCenter.default
                              .publisher(for: UIApplication.keyboardWillHideNotification)
                              .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    var inputForm: some View {
        VStack(alignment: .center) {
            
            Text(title ?? "Invite Users to \(room.name ?? "This Room")")
                .font(.title3)
                .fontWeight(.bold)
                .padding()

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    searchField
                    addButton
                }
                
                if !self.suggestions.isEmpty {
                    ScrollView {
                        /*
                        Text("SEARCH SUGGESTIONS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        */
                        ForEach(suggestions) { userId in
                            let user = room.session.getUser(userId: userId)
                            //Text("User \(userId.description)")
                            Button(action: {
                                self.newestUserIdString = ""
                                self.suggestions = []
                                self.newUsers.append(user)
                                self.searchFocused = false
                            }) {
                                MessageAuthorHeader(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxHeight: 300)
                    .padding(.bottom)
                    .padding(.leading)
                    Divider()
                }
                
                Spacer()
            }
            .padding(.leading)
            
                
            VStack(alignment: .leading) {
                Text("USERS TO INVITE")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                let columns = [
                    GridItem(.adaptive(minimum: 150))
                ]
                
                LazyVGrid(columns: columns) {
                    
                    ForEach(newUsers) { user in
                        Button(action: {
                            let userId = user.userId
                            self.newUsers.removeAll(where: {$0.userId == userId})
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

            
            if !showingKeyboard {
                Spacer()
                
                VStack {
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
                    .padding(5)
                    
                    Button(role: .destructive, action: {
                        self.pending = false
                        self.presentation.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .padding(5)
                    }
                }
                //.ignoresSafeArea(.keyboard)
            }
        }
        .padding()
        .onReceive(keyboardPublisher) {
            if $0 == 0 {
                self.showingKeyboard = false
            } else {
                self.showingKeyboard = true
            }
        }

 

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
