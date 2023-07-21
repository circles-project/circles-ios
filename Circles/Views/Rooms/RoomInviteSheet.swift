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
                                .filter { !currentUserIds.contains($0) }
                            print("INVITE:\tGot \(suggestedUserIds.count) search results: \(suggestedUserIds)")
                            await MainActor.run {
                                self.suggestions = suggestedUserIds
                                self.searchTask = nil
                            }
                        }
                    }
                    .frame(maxWidth: 300)

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
