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
    
    var body: some View {
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
            
            Spacer()
            
            Button(action: {
                let dgroup = DispatchGroup()
                var errors: KSError? = nil
                
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
                    if errors == nil {
                        self.presentation.wrappedValue.dismiss()
                    }
                }
            }) {
                Label("Send Invitation(s)", systemImage: "envelope")
            }
            .padding()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            //.padding()
        }
        .padding()
    }
}

/*
struct ChannelInviteSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChannelInviteSheet()
    }
}
*/
